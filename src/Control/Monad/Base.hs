{-# LANGUAGE CPP #-}
{-# LANGUAGE UnicodeSyntax #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE FunctionalDependencies #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE UndecidableInstances #-}

module Control.Monad.Base (
    MonadBase(..), liftBaseDefault
  ) where

import Data.Monoid
import Data.Functor.Identity
import qualified Control.Monad.ST.Lazy as L
import qualified Control.Monad.ST.Strict as S
import Control.Monad.Trans.Class
import Control.Monad.Trans.Identity
import Control.Monad.Trans.Maybe
import Control.Monad.Trans.List
import Control.Monad.Trans.Reader
import qualified Control.Monad.Trans.Writer.Lazy as L
import qualified Control.Monad.Trans.Writer.Strict as S
import qualified Control.Monad.Trans.State.Lazy as L
import qualified Control.Monad.Trans.State.Strict as S
import qualified Control.Monad.Trans.RWS.Lazy as L
import qualified Control.Monad.Trans.RWS.Strict as S
import Control.Monad.Trans.Error
import Control.Monad.Trans.Cont
import GHC.Conc.Sync                   ( STM )
import Text.ParserCombinators.ReadP    ( ReadP )
import Text.ParserCombinators.ReadPrec ( ReadPrec )
import Control.Arrow                   ( ArrowApply, ArrowMonad )

class (Monad m, Monad b) ⇒ MonadBase m b | m → b where
  -- | Lift a computation from the base monad
  liftBase ∷ b α → m α

#define BASE(CTX, M) \
instance (CTX) ⇒ MonadBase (M) (M) where liftBase = id

BASE(, IO)
BASE(, L.ST s)
BASE(, S.ST s)
BASE(, STM)
BASE(, Maybe)
BASE(, Either e)
BASE(, [])
BASE(, ReadP)
BASE(, ReadPrec)
BASE(, (→) r)
BASE(ArrowApply a, ArrowMonad a)
BASE(, Identity)
#undef BASE

-- | Can be used as a default implementation for 'liftBase'.
--
-- Note that: @liftBaseDefault = 'lift' . 'liftBase'@
liftBaseDefault ∷ (MonadTrans t, MonadBase m b) ⇒ b α → t m α
liftBaseDefault = lift . liftBase

#define TRANS(T) \
instance (MonadBase m b) ⇒ MonadBase (T m) b where liftBase = liftBaseDefault

TRANS(IdentityT)
TRANS(MaybeT)
TRANS(ListT)
TRANS(ReaderT r)
TRANS(L.StateT s)
TRANS(S.StateT s)
TRANS(ContT r)
#undef TRANS

#define TRANS_CTX(CTX, T) \
instance (CTX, MonadBase m b) ⇒ MonadBase (T m) b where liftBase = liftBaseDefault

TRANS_CTX(Monoid w, L.WriterT w)
TRANS_CTX(Monoid w, S.WriterT w)
TRANS_CTX(Monoid w, L.RWST r w s)
TRANS_CTX(Monoid w, S.RWST r w s)
TRANS_CTX(Error e,  ErrorT e)
#undef TRANS_CTX
