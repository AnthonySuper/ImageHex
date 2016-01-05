class Chat extends React.Component{
  constructor(props){
    super(props);
    this.state = {
      unread: props.initialUnread,
      hasFetchedConversations: false
    }
  }
  render(){
    if(this.state.active){
      if(! this.state.conversationCollection){
        return <div>
          <progress></progress>
        </div>;
      }
      var c = this.state.conversationsCollection.map((conv) => {
        return <ConversationComponent conversation={conv} />;
      });
      return <div>
      </div>;
    }
    else{
      var unreadCount = this.unreadMessageCount();
      return <div onClick={this.activate.bind(this)}>
        Chat ({unreadCount} messages unread)
      </div>;
    }
  }
  unreadMessageCount(){
    this.state.unread.length;
  }
  activate(){
    console.log("Activating chat");
    if(! this.state.conversationCollection){
      ConversationCollection.getCurrent((conv) => {
        console.log("Got current collection", conv);
        this.setState({
          conversationCollection: conv
        });
      });
    }
    var obj = {active: true}
    if(this.state.unread && this.state.conversationCollection){
      obj[unread] = [];
      this.state.conversationCollection.addMessages(this.state.unread);
    }
    this.setState(obj);
  }
}

document.addEventListener("page:change", function(){
  if(! USER_SIGNED_IN){
    return;
  }
  var elem = document.getElementById("chatbox");
  console.log("Got element",elem,"for chat");
  Message.unread((msg) => {
    ReactDOM.render(<Chat initialUnread={msg} />,
                    elem);
  });
});
