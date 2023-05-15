#!/bin/bash

function misc::timing::start(){
  SECONDS=0  ## linux built-in
}

#############################
function misc::timing::elapse() {
  echo "[INFO]: time elasped : $SECONDS (s)"
}