module Api
  module V1
    class ArticlesController < ApplicationController
      def index
        @cache_hit = true
        result = Rails.cache.fetch("articles/index", expires_in: 5.minutes) do
          @cache_hit = false
          Article.all.to_a
        end
        render json: result
      end

      def show
        @cache_hit = true
        result = Rails.cache.fetch("articles/#{params[:id]}", expires_in: 5.minutes) do
          @cache_hit = false
          Article.find(params[:id])
        end
        render json: result
      end

      def create
        article = Article.new(article_params)
        if article.save
          Rails.cache.delete("articles/index")
          render json: article, status: :created
        else
          render json: article.errors, status: :unprocessable_entity
        end
      end

      def update
        article = Article.find(params[:id])
        if article.update(article_params)
          Rails.cache.delete("articles/index")
          Rails.cache.delete("articles/#{params[:id]}")
          render json: article
        else
          render json: article.errors, status: :unprocessable_entity
        end
      end

      def destroy
        Article.find(params[:id]).destroy
        Rails.cache.delete("articles/index")
        Rails.cache.delete("articles/#{params[:id]}")
        head :no_content
      end

      private

      def article_params
        params.require(:article).permit(:title, :content)
      end
    end
  end
end
