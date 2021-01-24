require 'rails_helper'

RSpec.describe Message, type: :model do
  describe '#create' do
    before do
      @message = FactoryBot.build(:message)
    end

    it 'contentとimageが存在していれば保存できること' do
      expect(@message).to be_valid
    end

    it 'contentが空でも保存できること' do
      @message.content = nil
      expect(@message).to be_valid
    end

    it 'imageが空でも保存できること' do
      @message.image = nil
      expect(@message).to be_valid
    end

    it 'contentとimageが空では保存できないこと' do
      @message.content = nil
      @message.image = nil
      @message.valid?
      expect(@message.errors.full_messages).to include "Content can't be blank"
    end

    it 'roomが紐付いていないと保存できないこと' do
      @message.room = nil
      @message.valid?
      expect(@message.errors.full_messages).to include "Room must exist"
    end

    it 'userが紐付いていないと保存できないこと' do
      @message.user = nil
      @message.valid?
      expect(@message.errors.full_messages).to include "User must exist"
    end
  end
end

RSpec.describe "メッセージ投稿機能", type: :system do
  before do
    # 中間テーブルを作成して、usersテーブルとroomsテーブルのレコードを作成する
    @room_user = FactoryBot.create(:room_user)
  end

  context '投稿に失敗したとき' do
    it '送る値が空の為、メッセージの送信に失敗すること' do
      # サインインする
      sign_in(@room_user.user)
      # 作成されたチャットルームへ遷移する
      click_on(@room_user.room.name)
      # DBに保存されていないことを確認する
      expect {
        find('input[name="commit"]').click
      }.not_to change { Message.count }
      # 元のページに戻ってくることを確認する
      expect(current_path).to eq room_messages_path(@room)
    end
  end

  context '投稿に成功したとき' do
    it 'テキストの投稿に成功すると、投稿一覧に遷移して、投稿した内容が表示されている' do
      # サインインする
      sign_in(@room_user.user)
      # 作成されたチャットルームへ遷移する
      click_on(@room_user.room.name)
      # 値をテキストフォームに入力する
      test_post = "test"
      fill_in 'message_content', with: test_post
      # 送信した値がDBに保存されていることを確認する
      expect {
        find('input[name="commit"]').click
      }.to change { Message.count }.by(1)
      # 投稿一覧画面に遷移していることを確認する
      expect(current_path).to eq room_messages_path(@room)
      # 送信した値がブラウザに表示されていることを確認する
      expect(page).to have_content(test_post)
    end

    it '画像の投稿に成功すると、投稿一覧に遷移して、投稿した画像が表示されている' do
      # サインインする
      sign_in(@room_user.user)
      # 作成されたチャットルームへ遷移する
      click_on(@room_user.room.name)
      # 添付する画像を定義する
      image_path = Rails.root.join('public/images/test_image.png')
      # 画像選択フォームに画像を添付する
      attach_file('message[image]', make_visible: true, image_path)
      # 送信した値がDBに保存されていることを確認する
      expect {
        find('input[name="commit"]').click
      }.to change { Message.count }.by(1)
      # 投稿一覧画面に遷移していることを確認する
      expect(current_path).to eq room_messages_path
      # 送信した画像がブラウザに表示されていることを確認する
      expect(page).to have_selector("img")
    end

    it 'テキストと画像の投稿に成功すること' do
      # サインインする
      sign_in(@room_user.user)
      # 作成されたチャットルームへ遷移する
      click_on(@room_user.room.name)
      # 添付する画像を定義する
      image_path = Rails.root.join('public/images/test_image.png')
      # 画像選択フォームに画像を添付する
      attach_file('message[image]', make_visible: true, image_path)
      # 値をテキストフォームに入力する
      test_post = "test"
      fill_in 'message_content', with: test_post
      # 送信した値がDBに保存されていることを確認する
      expect {
        find('input[name="commit"]').click
      }.to change { Message.count }.by(1)
      # 送信した値がブラウザに表示されていることを確認する
      expect(page).to have_content(test_post)
      # 送信した画像がブラウザに表示されていることを確認する
      expect(page).to have_selector("img")
    end
  end
end

RSpec.describe "チャットルームの削除機能", type: :system do
  before do
    @room_user = FactoryBot.create(:room_user)
  end

  it 'チャットルームを削除すると、関連するメッセージがすべて削除されていること' do
    # サインインする
    sign_in(@room_user.user)
    # 作成されたチャットルームへ遷移する
    click_on(@room_user.room.name)
    # メッセージ情報を5つDBに追加する
    FactoryBot.create_list(:message, 5, room_id: @room_user)
    # 「チャットを終了する」ボタンをクリックすることで、作成した5つのメッセージが削除されていることを確認する
    expect {
      find_link("チャットを終了する", href: room_path(@room_user.room)).click
    }.to change { @room_user.room.messages.count }.by(-5)
    # トップページに遷移していることを確認する
    expect(current_path.to eq room_path)
  end
end