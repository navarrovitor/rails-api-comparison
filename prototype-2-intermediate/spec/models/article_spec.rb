require 'rails_helper'

RSpec.describe Article, type: :model do
  it 'is invalid without title' do
    article = Article.new(content: 'Some content')
    expect(article).not_to be_valid
  end

  it 'is invalid without content' do
    article = Article.new(title: 'Some title')
    expect(article).not_to be_valid
  end

  it 'is valid with title and content' do
    article = Article.new(title: 'Some title', content: 'Some content')
    expect(article).to be_valid
  end
end
