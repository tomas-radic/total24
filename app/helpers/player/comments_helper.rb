module Player::CommentsHelper

  def edit_comment_path(comment)
    helper_method = "edit_player_#{comment.commentable.class.to_s.downcase}_comment_path"
    public_send(helper_method, comment.commentable, comment)
  end


  def delete_comment_path(comment)
    helper_method = "delete_player_#{comment.commentable.class.to_s.downcase}_comment_path"
    public_send(helper_method, comment.commentable, comment)
  end
end
