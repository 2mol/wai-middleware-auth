{-# OPTIONS_HADDOCK hide, not-home #-}
module Network.Wai.Auth.Internal
  ( OAuth2TokenBinary(..)
  , encodeToken
  , decodeToken
  ) where

import           Data.Binary                          (Binary(get, put), encode,
                                                      decodeOrFail)
import qualified Data.ByteString                      as S
import qualified Data.ByteString.Lazy                 as SL
import qualified Network.OAuth.OAuth2                 as OA2

decodeToken :: S.ByteString -> Either String OA2.OAuth2Token
decodeToken bs =
  case decodeOrFail $ SL.fromStrict bs of
    Right (_, _, token) -> Right $ unOAuth2TokenBinary token
    Left (_, _, err) -> Left err

encodeToken :: OA2.OAuth2Token -> S.ByteString
encodeToken = SL.toStrict . encode . OAuth2TokenBinary

newtype OAuth2TokenBinary =
  OAuth2TokenBinary { unOAuth2TokenBinary :: OA2.OAuth2Token }
  deriving (Show)

instance Binary OAuth2TokenBinary where
  put (OAuth2TokenBinary token) = do
    put $ OA2.atoken $ OA2.accessToken token
    put $ OA2.rtoken <$> OA2.refreshToken token
    put $ OA2.expiresIn token
    put $ OA2.tokenType token
    put $ OA2.idtoken <$> OA2.idToken token
  get = do
    accessToken <- OA2.AccessToken <$> get
    refreshToken <- fmap OA2.RefreshToken <$> get
    expiresIn <- get
    tokenType <- get
    idToken <- fmap OA2.IdToken <$> get
    pure $ OAuth2TokenBinary $
      OA2.OAuth2Token accessToken refreshToken expiresIn tokenType idToken
