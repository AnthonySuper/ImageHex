
var Message = {}

Message.uploaded_image_commented_on = ({user_name}) => (
  `${user_name} replied to your comment`
  );

Message.comment_replied_to = ({user_name}) => (
  `${user_name} replied to your comment`
  );

Message.mentioned = ({user_name}) => (
   `${user_name} mentioned you in a comment`
   );

Message.new_subscriber = ({name}) => (
  `${name} has started following you`
  );

Message.order_confirmed = ({customer_name}) => (
  `${customer_name} ordered a commission from you`
  )

Message.order_accepted = ({seller_name}) => (
  `${seller_name} accepted your order`
  );

Message.order_paid = ({customer_name}) => (
  `${customer_name} just paid for their order!`
);

Message.order_rejected = ({seller_name}) => (
  `${seller_name} rejected your order.`
);


Message.order_filled = ({seller_name}) => (
  `${seller_name} just filled your order!`
);

export default Message;
