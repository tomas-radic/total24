class Player::CommentsController < Player::BaseController

  after_action :verify_authorized


  def create
    authorize @comment
    @comment.player = current_player

    if @comment.save
      recipients = NotificationRecipientsQuery.call(@comment.commentable, NewCommentNotifier, exclude: [current_player.id])
      NewCommentNotifier.with(record: @comment.commentable).deliver(recipients)
      redirect_back(fallback_location: root_path)
    else
      render turbo_stream: turbo_stream.replace(
        "comment-form",
        partial: "player/comments/form",
        locals: {
          comment: @comment
        }), status: :unprocessable_entity
    end
  end


  def edit
    @comment = current_player.comments.find(params[:id])
    authorize @comment
  end


  def update
    @comment = current_player.comments.find(params[:id])
    authorize @comment

    if @comment.update(whitelisted_params)
      redirect_back(fallback_location: root_path)
    else
      render "player/comments/edit", status: :unprocessable_entity
    end
  end


  def delete
    @comment = current_player.comments.find(params[:id])
    authorize @comment
    @comment.update!(deleted_at: Time.now)

    redirect_back(fallback_location: root_path)
  end


  private

  def whitelisted_params
    params.require(:comment).permit(:content, :motive_id)
  end

end
