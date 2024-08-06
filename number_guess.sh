#!/bin/bash

PSQL="psql --username=postgres --dbname=number_guess -t --no-align -c"

RANDOM_NUMBER=$((RANDOM % 1000 + 1))

echo Enter your username:
read USERNAME

USER_ID=$($PSQL "SELECT user_id FROM users WHERE name = '$USERNAME'")

if [[ -z $USER_ID ]]
then
  echo Welcome, $USERNAME! It looks like this is your first time here.
  INSERT_USER_RESULT=$($PSQL "INSERT INTO users(name) VALUES ('$USERNAME')")
  USER_ID=$($PSQL "SELECT user_id FROM users WHERE name = '$USERNAME'")
  IS_FIRST_GAME=1
else
  IFS="|" read BEST_GAME GAMES_PLAYED <<< $($PSQL "SELECT best_game, games_played FROM games WHERE user_id = '$USER_ID'")
  echo Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses.
fi

GUESS_NUMBER=0
echo "Guess the secret number between 1 and 1000:"

while : ; do
  read USER_NUMBER
  GUESS_NUMBER=$(( GUESS_NUMBER + 1 ))
  if ! [[ $USER_NUMBER =~ ^[0-9]+$ ]]
  then
    echo That is not an integer, guess again:
  elif [[ $USER_NUMBER == $RANDOM_NUMBER ]]
  then
    echo You guessed it in $GUESS_NUMBER tries. The secret number was $RANDOM_NUMBER. Nice job!
    # check first game
    if [[ -z $IS_FIRST_GAME ]]
    then
      if [[ $BEST_GAME > $GUESS_NUMBER ]]
      then
        BEST_GAME=$GUESS_NUMBER
      fi
      GAMES_PLAYED=$(( GAME_PLAYED + 1 ))
      UPDATE_RESULT=$($PSQL "UPDATE games SET best_game = $BEST_GAME, games_played = $GAMES_PLAYED WHERE user_id = $USER_ID")
    else
      INSERT_RESULT=$($PSQL "INSERT INTO games(user_id, best_game, games_played) VALUES($USER_ID, $GUESS_NUMBER, 1)")
    fi

    break
  elif [[ $USER_NUMBER < $RANDOM_NUMBER ]]
  then
    echo "It's higher than that, guess again:"
  else
    echo "It's lower than that, guess again:"
  fi
done