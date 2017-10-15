module Lab6 where

import Control.Monad 
import Lecture6
import Data.List
import Data.Bits
import Control.Exception
import Data.Time
import System.Random
import Formatting
import Formatting.Clock
import System.Clock
import Control.Monad
-- Define Main --
main = do
    putStrLn "===================="
    putStrLn "Assignment 6 / Lab 6"
    putStrLn "===================="
    putStrLn "> Exercise 1"
    exercise1
    putStrLn "> Exercise 2"
    exercise2
    putStrLn "> Exercise 3"
    exercise3
    putStrLn "> Exercise 4"
    exercise4
    putStrLn "> Exercise 5"
    exercise5
    putStrLn "> Exercise 6 (1)"
    exercise6
    putStrLn "> Exercise 6 (2)"
    exercise62
    putStrLn "> Exercise 7 (BONUS)"
    exercise7

-- =============================================================================
-- Exercise 1 :: Time spent: +- 5 hours
-- While implementing multiple versions of the exM function I came acros a package
-- that implemented the function if the squaring method. 
-- =============================================================================

exercise1 = do
  print()

-- This the implimentation found in the crypto-numbers package -- Using exponentiation by squaring
exM' :: Integer -> Integer -> Integer -> Integer
exM' 0 0 m = 1 `mod` m
exM' b e m = loop e b 1
    where sq x          = (x * x) `mod` m
          loop 0 _  a = a `mod` m
          loop i s a = loop (i `shiftR` 1) (sq s) (if odd i then a * s else a)
  
exM'' 0 _ m = 1 `mod` m
exM'' b e m = f e b 1
      where 
        f e' b' r | e' <= 0 = r
                | ((e' `mod` 2) == 1) = f (e' `shiftR` 1) ((b' * b') `mod` m) ((r * b') `mod` m)
                | otherwise = f (e' `shiftR` 1) ((b' * b') `mod` m) (r)
 
-- =============================================================================
-- Exercise 2 :: Time spent: +- 2 hours
-- A fair test should apply the same inputs to each function
-- It first generate 3 list of input and use them with both functions
-- =============================================================================
exercise2 = do
    bs <- replicateM  10000000 (randomRIO (400, 10000 :: Integer))
    es <- replicateM  10000000 (randomRIO (400, 10000 :: Integer))
    ms <- replicateM  10000000 (randomRIO (400, 10000 :: Integer))
    start <- getTime Monotonic
    print $ last $  last $ doCalculation' expM bs es ms
    end <- getTime Monotonic
    
    start' <- getTime Monotonic
    print $ last $  last $ doCalculation' exM'' bs es ms
    end' <- getTime Monotonic
    fprint (timeSpecs) start end
    fprint (timeSpecs) start' end'


doCalculation = do
  b <- randomRIO (1, 10000)
  e <- randomRIO (1, 10000)
  m <- randomRIO (1, 10000)
  evaluate (exM b e m)


doCalculation' :: (Integer -> Integer -> Integer -> Integer) -> [Integer] -> [Integer] -> [ Integer] ->[[Integer]]
doCalculation' fn bs es ms = do
  let z = zip3 bs es ms
  let ys = map (runFn) z
  return ys
  where 
    runFn (b, e , m) = fn b e m
  

randomInt = do
    x <- randomRIO (0, 10000 :: Int)
    return x

-- =============================================================================
-- Exercise 3 :: Time spent: +- 20 minutes
-- Since every whole number over 1 is either a composite number or a prime number
-- I can check if the number is not a prime number
-- =============================================================================
exercise3 = do
  print $ take 100 composites'

composites' :: [Integer]
composites' = filter (not.prime) [4..]
-- =============================================================================
-- Exercise 4 :: Time spent: +- 1 hour
-- The smallest composite number that passes the test is 9
-- If k = 1 it runs fast if k = 2 then takes a little longer but comes to the same conclusion. Running k = 3
-- takes a lot longer and got as low as 15 in one test.
-- =============================================================================
exercise4 = do
  k1Small <- testFer (testFermatKn 1)
  k2Small <- testFer (testFermatKn 2)
  k3Small <- testFer (testFermatKn 3)

  putStrLn " Exercise 4: Smallest composite number that passes Fermat test"
  putStrLn " K = 1 "
  print k1Small
  putStrLn " K = 2 "
  print k2Small
  putStrLn " K = 3 "
  print k3Small
  
testFer x =  testFerAvg x

testFerAvg tk = do
  x <- replicateM 10 tk
  let sorted = (sum x) `div` 10
  return $  sorted

testFerSmall tk = do
  x <- replicateM 10 tk
  let sorted = sort x
  return $ head sorted

testFermatKn n= foolFermat' n composites

foolFermat' :: Int -> [Integer] -> IO Integer
foolFermat' k (x:xs) = do
    z <- primeTestsF k x
    if z then
      return x
    else
      foolFermat' k xs


-- =============================================================================
-- Exercise 5 :: Time spent: +- 2 hours
-- This function uses J. Chernick's theorem to construct a subset of carmichael numbers.
-- The fermat test is easily by the first 2 numbers produced by the carmichael function
-- =============================================================================
exercise5 = do
  k1 <- testFer (testFermatCarmichaelKn 1)
  k2 <- testFer (testFermatCarmichaelKn 2)
  k3 <- testFer (testFermatCarmichaelKn 3)
  putStrLn " Exercise 5: Smallest number in J. Chernick's subset of carmichael numbers that passes Fermat test"
  putStrLn " K = 1 "
  print k1
  putStrLn " K = 2 "
  print k2
  putStrLn " K = 3 "
  print k3

testFermatCarmichaelKn n= foolFermat' n carmichael

carmichael :: [Integer]
carmichael = [ (6*k+1)*(12*k+1)*(18*k+1) | 
          k <- [2..], 
          prime (6*k+1), 
          prime (12*k+1), 
          prime (18*k+1) ]

-- =============================================================================
-- Exercise 6 (1) :: Time spent: +- 30 min
-- The numbers are much larger but the Miller-Rabin primality check does get fooled.
-- =============================================================================
exercise6 = do
  k1 <- testFer (testMRKn 1)
  k2 <- testFer (testMRKn 2)
  k3 <- testFer (testMRKn 3)
  putStrLn " Exercise 6: Smallest number in J. Chernick's subset of carmichael numbers that passes Miller-Rabin"
  putStrLn " K = 1 "
  print k1
  putStrLn " K = 2 "
  print k2
  putStrLn " K = 3 "
  print k3

testMRKn n = testMR n carmichael

testMR :: Int -> [Integer] -> IO Integer
testMR k (x:xs) = do
    z <- primeMR k x
    if z then
      return x
    else
      testMR k xs  

-- =============================================================================
-- Exercise 6 (2) :: Time spent: +- 15 minutes
-- I manage to get to 607 easily but then the program hangs.
-- =============================================================================
exercise62 = do
  filterM ((primeMR 1).(\x -> ((2^x) - 1 ))) $ take 150 primes
    
-- =============================================================================
-- Exercise 7 :: Time spent: +-
-- =============================================================================
exercise7 = do
  print()
