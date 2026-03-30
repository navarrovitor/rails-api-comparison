require 'rails_helper'

RSpec.describe User, type: :model do
  it 'is invalid without email' do
    user = User.new(password: '123456')
    expect(user).not_to be_valid
  end

  it 'is invalid with duplicate email' do
    User.create!(email: 'test@test.com', password: '123456')
    user = User.new(email: 'test@test.com', password: 'abcdef')
    expect(user).not_to be_valid
  end

  it 'is invalid without password' do
    user = User.new(email: 'test@test.com')
    expect(user).not_to be_valid
  end

  it 'is valid with email and password' do
    user = User.new(email: 'test@test.com', password: '123456')
    expect(user).to be_valid
  end
end
