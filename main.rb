require 'rubygems'
require 'sinatra'

set :sessions, true

BLACKJACK = 21
DEALER_MIN = 17

helpers do
  def calculate_total(cards)
    arr = cards.map { |element| element[1] }

    total = 0
    arr.each do |a|
      if a == 'A'
        total += 11
      else
        total += a.to_i == 0 ? 10 : a.to_i
      end
    end

    # correct for Aces
    arr.select { |element| element == 'A' }.count.times do
      break if total <= BLACKJACK
      total -= 10
    end

    total
  end

  def card_image(card)
    suit = case card[0]
           when 'H' then 'hearts'
           when 'S' then 'spades'
           when 'D' then 'diamonds'
           when 'C' then 'clubs'
           end

    rank = card[1]

    if %w(J Q K A).include?(rank)
      rank = case card[1]
             when 'J' then 'jack'
             when 'Q' then 'queen'
             when 'K' then 'king'
             when 'A' then 'ace'
             end
    end

    "<img src='/images/cards/#{suit}_#{rank}.jpg' class='card_image'>"
  end

  def win!(message)
    @play_again = true
    @show_buttons = false
    @success = "<strong>You won, #{session[:player]}!</strong> #{message}"
  end

  def lose!(message)
    @play_again = true
    @show_buttons = false
    @error = "<strong>Sorry, #{session[:player]}. You lost.</strong> #{message}"
  end

  def draw!(message)
    @play_again = true
    @show_buttons = false
    @alert = "<strong>It's a tie!</strong> #{message}"
  end
end

before do
  @show_buttons = true
end

get '/' do
  if session[:player]
    redirect '/game'
  else
    redirect '/new_player'
  end
end

get '/new_player' do
  erb :new_player
end

post '/new_player' do
  if params[:player].empty?
    @error = 'Oops! You forgot to enter your name.'
    halt erb(:new_player)
  end

  session[:player] = params[:player]
  redirect '/game'
end

get '/game' do
  session[:turn] = session[:player]

  suits = %w(H S D C)
  ranks = %w(2 3 4 5 6 7 8 9 10 J Q K A)
  session[:deck] = []
  session[:deck] = suits.product(ranks).shuffle!

  session[:dealer_cards] = []
  session[:player_cards] = []
  session[:dealer_cards] << session[:deck].pop
  session[:player_cards] << session[:deck].pop
  session[:dealer_cards] << session[:deck].pop
  session[:player_cards] << session[:deck].pop

  player_total = calculate_total(session[:player_cards])
  dealer_total = calculate_total(session[:dealer_cards])

  if dealer_total == BLACKJACK
    lose!('The dealer hit blackjack. Better luck next time.')
  elsif dealer_total == BLACKJACK && player_total == BLACKJACK
    draw!('You both hit blackjack!')
  end

  erb :game
end

post '/game/player/hit' do
  session[:player_cards] << session[:deck].pop

  player_total = calculate_total(session[:player_cards])

  if player_total == BLACKJACK
    win!('You hit blackjack!')
  elsif player_total > BLACKJACK
    lose!("You got greedy and you busted at #{player_total}." \
          ' Better luck next time.')
  end

  erb :game
end

post '/game/player/stay' do
  redirect '/game/dealer'
end

get '/game/dealer' do
  session[:turn] = 'dealer'

  @show_buttons = false

  dealer_total = calculate_total(session[:dealer_cards])

  if dealer_total > BLACKJACK
    win!("The dealer busted with #{dealer_total}.")
  elsif dealer_total >= DEALER_MIN && dealer_total >= player_total
    redirect '/game/compare'
  else
    @show_dealer_hit_button = true
  end

  erb :game
end

post '/game/dealer/hit' do
  session[:dealer_cards] << session[:deck].pop

  redirect '/game/dealer'
end

get '/game/compare' do
  @show_buttons = false

  player_total = calculate_total(session[:player_cards])
  dealer_total = calculate_total(session[:dealer_cards])

  if player_total > dealer_total
    win!("You stayed at #{player_total}," \
         " and the dealer stayed at #{dealer_total}.")
  elsif player_total < dealer_total
    lose!("You stayed at #{player_total}," \
          " and the dealer stayed at #{dealer_total}.")
  else
    draw!("You stayed at #{player_total}," \
          " and the dealer stayed at #{dealer_total}.")
  end

  erb :game
end

get '/game_over' do
  erb :game_over
end
