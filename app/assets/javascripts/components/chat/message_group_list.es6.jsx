class MessageGroupList extends React.Component {
  constructor(props){
    super(props);
    this.state = {};
  }
  render() {
    var groups = this.props.messageGroups.map((group) => {
      return <MessageGroupList.MessageGroup {...group} />;
    });
    return <ul className="conversation-message-groups in-react">
      {groups}
    </ul>;
  }
}

MessageGroupList.MessageGroup = (group) => (
  <li className="conversation-message-group">
    <div className="message-group-avatar">
      <img src={group.user.avatar_path} />
    </div>
    <div className="message-group-body">
      <div className="message-group-user-section">
        <span className="user-name">{group.user.name}</span>
        <time dateTime={group.lastMessageAt}>
          {group.lastMessageAt.toLocaleString()}
        </time>
      </div>
      <ul className="message-group-messages">
        { 
          group.messages.map((m) => (
            <li key={m.id}>
              {m.body}
            </li>
            ))
        }
      </ul>
    </div>
  </li>
  );