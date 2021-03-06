import React from 'react';
import App from '../../../cable';
import NM from '../../../api/global.es6';
import MessageGroup from './message_group.es6.jsx';
import TransitionGroup from 'react-addons-css-transition-group';

import {
  getHistoryBefore, 
  startUpdate, 
  endUpdate, 
  markRead,
  changeConversation
} from '../actions.es6';

const UnreadSeperator = ({lastReadAt}) => {
    return <div className="read-seperator" key="seperator">
      Unread since <span> </span>
      <date dateTime={lastReadAt}>
        {lastReadAt.toLocaleString()}
      </date>
    </div>;
};

function groupChunk(messages, users, lastReadAt) {
  if(messages.length === 0) {
    return "";
  }
  let addedSeperator = false;
  // Only add the unread seperator if it happened more than 15 seconds ago
  let shouldAddSep = Date.now() - lastReadAt.getTime() > 15000;
  let userId = messages[0].user_id;
  let components = [];
  let msgBuffer = [];
  // Dump the message buffer in as a group
  function flushBuffer() {
    if(msgBuffer.length > 0) {
      components.push(<MessageGroup
        messages={msgBuffer.slice()}
        user={users[userId]}
        key={msgBuffer[0].id} />);
    }
    msgBuffer = [];
  };

  messages.forEach((message, index) => {
    if((new Date(message.created_at) > new Date(lastReadAt)) 
       && ! addedSeperator && shouldAddSep) {
      flushBuffer();
      components.push(<UnreadSeperator key="unread-sep"
                      lastReadAt={lastReadAt} />);
      addedSeperator = true;
    }
    if(message.user_id === userId) {
      msgBuffer.push(message);
    }
    else {
      // Flush to an actual group
      flushBuffer();
      // set current user id to new user id
      userId = message.user_id;
      // append current message to new buffer
      msgBuffer.push(message);
    }

    // if msgBuffer is too long, flush it to a group again
    if(msgBuffer.length > 6) {
      flushBuffer();
    }
  });
  flushBuffer();
  return components;
}

class Conversation extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      containerClass: "active-conversation downwards"
    };
  }

  render() {
    var upperSuffix = "";
    let {messages, users, lastReadAt} = this.props;
    let mapped = groupChunk(messages, users, lastReadAt);
    if(this.props.updating) {
      upperSuffix = " updating";
    }
    return <div className={this.state.containerClass}
        ref={(i) => this._overall = i} >
      <div className={"conversation-upper" + upperSuffix} >
        <h5>{this.props.conversation.name}</h5>
        <a className="close-chat"
          onClick={() => this.context.dispatch(changeConversation(null))} />

      </div>
      <ul className="message-group-list"
        ref={(i) => this._list = i}
        onScroll={this.onScroll.bind(this)}>
        <TransitionGroup
          transitionName="message-slide"
          transitionEnterTimeout={250}
          transitionLeaveTimeout={250}>
          {mapped}
        </TransitionGroup>
      </ul>
      <input className="message-input"
        ref={(e) => this._input = e}
        onKeyUp={this.keyUp.bind(this)} />
    </div>;
  }

  componentDidMount() {
    console.log("Active conversation component mounted");
    if(this.props.messages.length < 15) {
      this.fetchOlder();
    }
    $(window).on("turbolinks:before-visit.chatComponent", (event) => {
      let list = this._list;
      this.loadScrollTop = list.scrollTop;
      console.log("Set scrolltop to", list.scrollTop);
    });
    $(window).on("turbolinks:load.chatComponent", (event) => {
      console.log("Have load scroll top of",this.loadScrollTop);
      let list = this._list;
      if(this.loadScrollTop) {
        list.scrollTop = this.loadScrollTop;
      }
    });
    this.setState({
      containerClass: "active-conversation"
    });
  }

  componentWillUnmount() {
    $(window).off("turbolinks:before-visit.chatComponent");
    $(window).off("turbolinks:load.chatComponent");
  }

  componentWillUpdate(nextProps, nextState) {
    let list = this._list;
    if(! list) {
      return;
    }
    let sT = list.scrollTop;
    let oH = list.offsetHeight;
    let sH = list.scrollHeight;
    this.shouldScrollToBottom = (Math.abs(((sT + oH) - sH)) < 4);
    this.scrollHeight = sH;
    this.scrollTop = sT;
  }

  componentDidUpdate(prevProps, prevState) {
    if(this.props.conversation.id !== prevProps.conversation.id) {
      let n = this.props.conversation.id;
      let o = prevProps.conversation.id;
      console.log(`Changed ID from ${n} to ${o}`);
      if(this.props.messages.length < 15) {
        console.log("Fetching older messages as we have changed conversation");
        this.fetchOlder();
      }
      this.checkForRead();
    }
    else {
      let list = this._list;
      if(this.shouldScrollToBottom) {
        list.scrollTop = list.scrollHeight;
      }
    }
  }

  componentWillReceiveProps(nextProps) {
    if(this.props.conversation.id !== nextProps.conversation.id) {
      this.clearInput();
    }
  }

  fetchOlder() {
    if(this.props.depletedHistory) {
      return false;
    }
    else {
      let cid = this.props.conversation.id;
      let beforeDate = this.getEldestDate();
      this.context.dispatch(getHistoryBefore(beforeDate, cid));
    }
  }

  getEldestDate() {
    if(this.props.messages.length === 0) {
      return new Date();
    }
    else {
      let eldestMessage = this.props.messages[0];
      if(eldestMessage.user_id === "unread_active") {
        eldestMessage = this.props.messages[1];
      }
      return new Date(eldestMessage.created_at);
    }
  }

  onScroll(event) {
    let list = event.target;
    if(list.scrollTop < 50) {
      this.fetchOlder();
    }
    this.checkForRead();
  }

  checkForRead() {
    if(! this.props.hasUnread || this.checkingForUnread) {
      return;
    }
    let list = this._list;
    let sT = list.scrollTop;
    let oH = list.offsetHeight;
    let sH = list.scrollHeight;
    if(sH > this._overall.scrollHeight) {
      console.log("It's less");
    }
    let cid = this.props.conversation.id;
    // If we're not at the bottom, return
    if(sT > 0 && Math.abs(((sT + oH) - sH)) > 4) {
      console.log("Not at the bottom, returning.");
      return;
    }
    this.checkingForUnread = true;
    App.chat.perform("read", {cid: cid});
    window.setTimeout(() => {this.checkingForUnread = false}, 1000);
  }

  keyUp(event) {
    if(event.shiftKey) {
      return;
    }
    else {
      // Enter key sends message
      if(event.keyCode === 13) {
        this.sendMessage();
      }
    }
  }

  async sendMessage() {
    var cid = this.props.conversation.id;
    var data = {message: {body: this._input.value}};
    this.context.dispatch(startUpdate());
    try {
      let cb = NM.postJSON(`/conversations/${cid}/messages`, data);
    }
    catch(err) {
      console.log("Got an erorr while posting:",err);
    }
    finally {
      this.context.dispatch(endUpdate());
      this.clearInput();
    }
  }

  clearInput() {
    if(this._input) {
      this._input.value = "";
    }
  }
}

Conversation.contextTypes = {
  store: React.PropTypes.object,
  dispatch: React.PropTypes.func
};

export default Conversation;
