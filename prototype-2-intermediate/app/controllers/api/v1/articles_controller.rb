module Api
  module V1
    class ArticlesController < ApplicationController
      def index
        render json: Article.all
      end

      def show
        render json: Article.find(params[:id])
      end

      def create
        article = Article.new(article_params)
        if article.save
          render json: article, status: :created
        else
          render json: article.errors, status: :unprocessable_entity
        end
      end

      private

      def article_params
        params.require(:article).permit(:title, :content)
      end
    end
  end
end
