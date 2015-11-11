{-# LANGUAGE TypeFamilies, MultiParamTypeClasses, RankNTypes#-}
{-# LANGUAGE CPP #-}
-----------------------------------------------------------------------------
-- |
-- Module      :  Numerical.PETSc.Internal.PutGet.TS
-- Copyright   :  (c) Marco Zocca 2015
-- License     :  LGPL3
-- Maintainer  :  Marco Zocca
-- Stability   :  experimental
--
-- | TS Mid-level interface
--
-----------------------------------------------------------------------------
module Numerical.PETSc.Internal.PutGet.TS where

import Numerical.PETSc.Internal.InlineC
import Numerical.PETSc.Internal.Types
import Numerical.PETSc.Internal.Exception
import Numerical.PETSc.Internal.Utils

import Foreign
import Foreign.C.Types

import System.IO.Unsafe (unsafePerformIO)

import Control.Monad
import Control.Arrow
import Control.Concurrent
import Control.Exception

import Control.Monad.ST (ST, runST)
import Control.Monad.ST.Unsafe (unsafeIOToST) -- for HMatrix bits

import qualified Data.Vector as V
import qualified Data.Vector.Storable as V (unsafeWith, unsafeFromForeignPtr, unsafeToForeignPtr)





tsCreate :: Comm -> IO TS
tsCreate comm = chk1 $ tsCreate' comm

tsDestroy :: TS -> IO ()
tsDestroy ts = chk0 $ tsDestroy' ts

-- withTs :: Comm -> (TS -> IO a) -> IO a
withTs tsc = bracket tsc tsDestroy

tsSetProblemType :: TS -> TsProblemType -> IO ()
tsSetProblemType ts ty = chk0 $ tsSetProblemType' ts ty

tsSetInitialTimeStep ::
  TS ->
  PetscReal_ -> -- initial time
  PetscReal_ -> -- initial timestep
  IO ()
tsSetInitialTimeStep ts it dt = chk0 $ tsSetInitialTimeStep' ts it dt


-- tsSetRHSFunction ts r f ctx = chk0 $ tsSetRHSFunction0' ts r f ctx

tsSetDuration ::
  TS ->
  Int ->  -- max. # steps
  PetscReal_ -> -- max. time
  IO ()
tsSetDuration ts ms mt = chk0 $ tsSetDuration' ts ms mt

tsSetSolution ::
  TS ->
  Vec ->        -- initial condition
  IO ()
tsSetSolution ts isolnv = chk0 $ tsSetSolution' ts isolnv

tsSolve_ :: TS -> IO ()
tsSolve_ ts = chk0 $ tsSolve_' ts

tsSolveWithInitialCondition :: TS -> Vec -> IO ()
tsSolveWithInitialCondition ts isolnv = do
  tsSetSolution ts isolnv
  tsSolve_ ts

tsSetDm :: TS -> DM -> IO ()
tsSetDm ts dm = chk0 (tsSetDm' ts dm)


-- | 

-- | F(t, u, du/dt)
tsSetIFunction_ ts res f = chk0 (tsSetIFunction0' ts res f)

tsSetIFunction ::
  TS ->
  Vec ->
  (TS -> PetscReal_ -> Vec -> Vec -> Vec -> IO CInt) ->
  IO ()
tsSetIFunction ts res f = tsSetIFunction_ ts res g where
  g t r a b c _ = f t r a b c


-- | G(t, u)

tsSetRHSFunction_ ts r f = chk0 (tsSetRHSFunction0' ts r f)

tsSetRHSFunction ::
  TS ->
  Vec ->
  (TS -> PetscReal_ -> Vec -> Vec -> IO CInt) ->
  IO ()
tsSetRHSFunction ts r f = tsSetRHSFunction_ ts r g where
  g t a b c _ = f t a b c
  
tsSetRHSJacobian_ ts amat pmat f = chk0 (tsSetRHSJacobian0' ts amat pmat f)

-- | gG/du

tsSetRHSJacobian ::
  TS ->
  Mat ->
  Mat ->
  (TS -> PetscReal_ -> Vec -> Mat -> Mat -> IO CInt) ->
  IO ()
tsSetRHSJacobian ts amat pmat f = tsSetRHSJacobian_ ts amat pmat g where
  g t a b c d _ = f t a b c d



-- | adjoint TS solve

tsSetSaveTrajectory :: TS -> IO ()
tsSetSaveTrajectory ts = chk0 $ tsSetSaveTrajectory' ts

tsTrajectoryCreate :: Comm -> IO TSTrajectory
tsTrajectoryCreate comm = chk1 (tsTrajectoryCreate' comm)

tsTrajectoryDestroy :: TSTrajectory -> IO ()
tsTrajectoryDestroy ts = chk0 (tsTrajectoryDestroy' ts)

tsSetCostGradients :: TS -> Int -> [Vec] -> [Vec] -> IO ()
tsSetCostGradients ts numcost lambda_ mu_ =
  withArray lambda_ $ \lp ->
  withArray mu_ $ \mp ->
   chk0 $ tsSetCostGradients' ts n lp mp where
     n = toCInt numcost

tsAdjointSetRHSJacobian ::
  TS ->
  Mat ->
  (TS -> PetscReal_ -> Vec -> Mat -> IO CInt) ->
  IO ()
tsAdjointSetRHSJacobian ts amat f  =
  chk0 $ tsAdjointSetRHSJacobian0' ts amat g where
    g a b c d _ = f a b c d

tsAdjointSolve :: TS -> IO ()
tsAdjointSolve ts = chk0 (tsAdjointSolve' ts)
