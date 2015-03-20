module Routing where

import Control.Monad.Eff
import Data.Maybe
import Data.Either
import qualified Data.String.Regex as R

import Routing.Parser
import Routing.Match

foreign import hashChanged """
function hashChanged(handler) {
  return function() {
    var currentHash = document.location.hash;
    handler("")(currentHash)();
    window.addEventListener("hashchange", function(ev) {
      handler(ev.oldURL)(ev.newURL)();
    });
  };
}
""" :: forall e. (String -> String -> Eff e Unit) -> Eff e Unit 


hashes :: forall e. (String -> String -> Eff e Unit) -> Eff e Unit
hashes cb =
  hashChanged $ \old new -> do
    cb (dropHash old) (dropHash new)
  where dropHash h = R.replace (R.regex "^[^#]*#" R.noFlags) "" h


matches :: forall e a. Match a -> (Maybe a -> a -> Eff e Unit) -> Eff e Unit
matches routing cb = hashes $ \old new -> 
  let mr = matchHash routing 
      fst = either (const Nothing) Just $ mr old
  in either (const $ pure unit) (cb fst) $ mr new 


matchHash :: forall a. Match a -> String -> Either String a
matchHash matcher hash = runMatch matcher $ parse hash
