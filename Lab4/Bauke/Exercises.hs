module Lab4 where

import Data.List
import System.Random

import Lab4.SetOrd

import Test.QuickCheck
import Test.QuickCheck.Monadic

-- Define Main --
main = do
    putStrLn $ "===================="
    putStrLn $ "Assignment 4 / Lab 4"
    putStrLn $ "===================="
    putStrLn $ "> Exercise 1"
    exercise1
    putStrLn $ "> Exercise 2"
    exercise2
    putStrLn $ "> Exercise 3"
    exercise3
    putStrLn $ "> Exercise 4"
    exercise4
    putStrLn $ "> Exercise 5"
    exercise5
    putStrLn $ "> Exercise 6"
    exercise6
    putStrLn $ "> Exercise 7"
    exercise7
    putStrLn $ "> Exercise 8"
    exercise8
    putStrLn $ "> Exercise 9"
    exercise9
    putStrLn $ "> Exercise 10"
    exercise10

-- =============================================================================
-- Exercise 1 :: Time spent: +-
-- =============================================================================

exercise1 = print ()


-- =============================================================================
-- Exercise 2 :: Time spent +- 15 minutes
-- Simly took the random form generator from Lab 3 and added the Set part
-- =============================================================================
exercise2 = randomInt 100 >>= (\n -> randomSet n)

-- | Set of maximum n ordered items, no duplicates, sorted
randomSet :: Int -> IO (Set Int)
randomSet n = do
                xs <- randomIntegers n
                return $ Set ((sort . nub) xs)

randomIntegers :: Int -> IO [Int]
randomIntegers n = sequence [ randomInt 100 | a <- [1..n]]

randomInt :: Int -> IO Int
randomInt n = randomRIO (0, n)

-- =============================================================================
-- Exercise 3 :: Time spent +- 30 minutes
-- Re-used the quickCheck MonadicIO from Lab 3, als added the properties
-- =============================================================================
exercise3 = do
  quickCheck prop_intersectionLength
  quickCheck prop_differenceLength

-- | Generates an intersection of two random sets
someIntersection :: IO (Set Int)
someIntersection = do
            xs <- randomSet 10
            ys <- randomSet 10
            return $ interSection xs ys

-- | Generates a difference of two random sets
someDifference :: IO (Set Int)
someDifference = do
            xs <- randomSet 10
            ys <- randomSet 10
            return $ difference xs ys

interSection, difference :: Ord a => Set a -> Set a -> Set a
interSection (Set xs) (Set ys) = (Set (intersect xs ys))
difference (Set xs) (Set ys) = (Set ((\\) xs ys))

prop_intersectionLength (Positive n) = monadicIO $ do
  result <- run $ validateIntersectionLength n
  assert (result)

validateIntersectionLength :: Int -> IO Bool
validateIntersectionLength n = do
  xs <- randomSet n
  ys <- randomSet n
  return $ (size xs) >= (size (interSection xs ys))

prop_differenceLength (Positive n) = monadicIO $ do
  result <- run $ validateDifferenceLength n
  assert (result)

validateDifferenceLength :: Int -> IO Bool
validateDifferenceLength n = do
  xs <- randomSet n
  ys <- randomSet n
  return $ (size xs) >= (size (difference xs ys))

-- | Custom size which returns the amounf of items in a set
size :: Ord a => Set a -> Int
size (Set xs) = length xs

-- =============================================================================
-- Exercise 4 :: Time spent +-
-- =============================================================================
exercise4 = do
  print()

-- =============================================================================
-- Exercise 5 :: Time spent +- 10 minutes
-- Simply a recursive concatenation of the lists
-- Used sample exercise along with one with two equal terms to show no duplicates in a set
-- =============================================================================
type Rel a = [(a,a)]

exercise5 = do
  putStr "Example is correct: "
  print $ [(1,2),(2,1),(2,3),(3,2),(3,4),(4,3)] == symClos [(1,2),(2,3),(3,4)]
  putStr "No duplicates for equal terms: "
  print $ [(1,1)] == symClos [(1,1)]

symClos :: Ord a => Rel a -> Rel a
symClos [] = []
symClos ((a,b):xs) = nub $ ((a,b):(b,a):(symClos xs))

-- =============================================================================
-- Exercise 6 :: Time spent +- 30 minutes
-- Same loop recursion utilizing the infixr operation
-- However, this could be solved using the fix / fp' from the workshop!
-- =============================================================================
inputRelation = [(1,2),(2,3),(3,4)]
expectedClosure = [(1,2),(1,3),(1,4),(2,3),(2,4),(3,4)]

exercise6 = do
  putStr "Expecting transitive closure to be correct: "
  print $ expectedClosure == (trClos inputRelation)

infixr 5 @@
(@@) :: Eq a => Rel a -> Rel a -> Rel a
r @@ s =
  nub [(x,z) | (x,y) <- r, (w,z) <- s, y == w]

trClos :: Ord a => Rel a -> Rel a
trClos xs | xs == result = sort xs
          | otherwise = trClos result
          where result = nub $ xs ++ (xs @@ xs)

-- =============================================================================
-- Exercise 7 :: Time spent +- 10 minutes
-- Adding a simple (hardly randomized) property to test
-- =============================================================================
exercise7 = do
  quickCheck prop_unchanged
  quickCheck prop_initialRelations

-- | For any closure with non-different fields, the output is the same
prop_unchanged :: Int -> Bool
prop_unchanged n =
  (a == trClos a) && (a == symClos a)
  where a = [(n,n)]

-- | All elements in the original set are present in the closure
prop_initialRelations n = monadicIO $ do
  result <- run (checkContent n)
  assert (result)

-- | Validate that all elements of a are present in b
checkContent :: Int -> IO Bool
checkContent n = do
  rels <- randomRelations n
  let sym = symClos rels
  if null $ (\\) rels sym
  then return True
  else do
    putStr "Input set: "
    print rels
    putStr "Symmettric closure: "
    print $ sym
    putStr "Difference between: "
    print $ (\\) rels sym
    return False

-- =============================================================================
-- Exercise 8 :: Time spent +- 60 minutes
-- Didn't even try to manually find counter examples
-- Relied on the quickCheck generator to generate an example every time
-- Keyed in the random generators + quickCheck property
-- Took some time to fix the syntactic sugar of the nested do loops
-- Note: Intentionally returns TRUE on both occasions, simply to not 'break' the loop on the first error
-- Looking at the printed counter examples, one can immediately see why the transitive closure of the
-- symmetric closure returns more items than the symmetric closure of the transitive closure
-- The symmetric closure of a (a,b) results in both (a,b) and (b,a)
-- When mapping the transitivity on this result, relations from (a,a) and (b,b) are found.
-- The transitive closure of (a,b) is still (a,b). Making that symmetric
-- Will result in only (a,b) and (b,a). This specific example added below
-- =============================================================================
exercise8 = do
  quickCheckWith stdArgs {maxSize = 10} prop_checkCompare
  simpleCounterExample

simpleCounterExample :: IO ()
simpleCounterExample = do
    let relation = [(0,1)]
    putStrLn $ "Simple counter example: " ++ show relation
    let stc = symTrClos relation
    let rsc = trSymClos relation
    putStrLn $ show stc ++ " /= " ++ show rsc

prop_checkCompare n = monadicIO $ do
  result <- run (checkComparison n)
  assert (result)

checkComparison :: Int -> IO Bool
checkComparison n = do
  rels <- randomRelations n
  let stClos = symTrClos rels
  let tsClos = trSymClos rels
  if stClos /= tsClos
  then do
    putStr "Error when checking: "
    print rels
    putStr "symmetric transitive: "
    print stClos
    putStr "transitive symmetric: "
    print tsClos
    return True
  else return True

-- | Generate some random values composing a set of maximum n elements
randomRelations :: Int -> IO (Rel Int)
randomRelations n = do
    rels <- sequence [ randomRelation n | a <- [1..n]]
    return $ nub rels

-- | Some random mapping from (a,b)
randomRelation :: Int -> IO (Int, Int)
randomRelation n = do
            a <- randomInt n
            b <- randomInt n
            return $ (a,b)

-- | First transitive closure, then symmetric
symTrClos :: Ord a => Rel a -> Rel a
symTrClos = symClos . trClos

-- | First symmetric, then transitive closure
trSymClos :: Ord a => Rel a -> Rel a
trSymClos = trClos . symClos

-- =============================================================================
-- Exercise 9 :: Time spent +-
-- =============================================================================
exercise9 = do
  print()

-- =============================================================================
-- Exercise 10 :: Time spent +- 60 minutes
-- First generated the brute force implementation
-- Works well up to approximately 2000 variables
-- =============================================================================
exercise10 = do
  print()

summedData :: Integer -> Integer
summedData n = sumUp n 0

sumUp :: Integer -> Integer -> Integer
sumUp n sum | n == 0 = sum
            | otherwise = sumUp (n-1) (nextSum sum)

nextSum :: Integer -> Integer
nextSum 0 = 1
nextSum n = n + splitInt n

splitInt :: Integer -> Integer
splitInt n = sum $ [ read [c] :: Integer | c <- (show n)]


