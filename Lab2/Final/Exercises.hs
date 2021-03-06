module Lab2 where

import Data.List
import Data.Char
import Data.Maybe
import System.Random
import Test.QuickCheck
import Text.Regex.Posix

-- Assignment 2 / Lab 2 :: Group 14 --
infix 1 -->
(-->) :: Bool -> Bool -> Bool
p --> q = (not p) || q
forall :: [a] -> (a -> Bool) -> Bool
forall = flip all


-- Define Main --
main = do
    putStrLn $ "===================="
    putStrLn $ "Assignment 2 / Lab 2"
    putStrLn $ "===================="
    putStrLn $ "> Exercise 1"
    exercise1
    putStrLn $ "> Exercise 2"
    exercise2
    putStrLn $ "> Exercise 3a"
    exercise3a
    putStrLn $ "> Exercise 3b"
    exercise3b
    putStrLn $ "> Exercise 4"
    exercise4
    putStrLn $ "> Exercise 5"
    exercise5
    putStrLn $ "> Exercise 6"
    exercise6
    putStrLn $ "> Exercise 7"
    exercise7
    putStrLn $ "> BONUS"
    exercisebonus

-- Exercise 1 :: Merged version of Jordan and Willem-Jan
--            :: Time spent: 180 minutes (really...) + 60 minutes merging/discussion

-- QuickCheck for generating a number of random values and checking that the value is maintained

probs :: Int -> IO [Float]
probs 0 = return []
probs n = do
  p <- getStdRandom random
  ps <- probs (n-1)
  return (p:ps)

exercise1 = quantilesIO 10000 4

quantilesIO :: Int -> Int -> IO()
quantilesIO xs q = do {
    p <- probs xs;
    print $ flip chi (div xs q) $ quantiles p [ fromIntegral x / (fromIntegral q) | x  <- [1..q]]
}

-- Using a chi squared test to verify if the bins are evenly distributed
-- https://en.wikipedia.org/wiki/Chi-squared_test
-- https://www.medcalc.org/manual/chi-square-table.php
-- Using (n-1) = (4-1) = 3 degrees a freedom and a P value of 0.05
-- The result of the chi should not exceed 7.815
-- In this case it doesn't exceed that value, so we can say the random generator is good,
-- based on the fact of dividing them into 4 bins, however we cannot see anything about the distribution within a bin.
chi :: [Int] -> Int -> Float
chi (x:xs) m = foldr (\ x -> (+) (fromIntegral ((x - m) ^ 2) / fromIntegral m)) 0 xs

quantiles :: [Float] -> [Float] -> [Int]
quantiles xs [] = []
quantiles xs (q:qs) = [genericLength $ filter (<q) xs] ++ (quantiles (filter (>=q) xs) qs)

-- Exercise 2 :: Modified Version (group effort) of Bauke
--            :: Time spent: 75 minutes (implementation/tests/discussion)
-- Implementation was simply keying in the definitions for the triangles
-- However, testing this proved to be more difficult. Main reason for this difficulty was due to the ambiguity
-- between Isosceles and Equilateral and the issue of generating Rectangular triangles
-- For the ambiguity we simply added 1 to the length of the sides
-- For testing the Rectangular data, we use a list of predefined rectangular triangles.
-- We use the the random index from QuickCheck to validate it.
-- This generates a wider variety than simply multiplying 1 random value with for instance 3,4,5.
-- When inspecting the list of triangles generated, it also displays rectangular triangles with other ratio's
-- than the standard 3,4,5 or 60,80,100 triangles

data Shape = NoTriangle | Equilateral | Isosceles | Rectangular | Other
             deriving (Eq, Show)

exercise2 = do
  quickCheck prop_noTriangle
  quickCheck prop_equilateral
  quickCheck prop_isosceles
  quickCheck prop_rectangular
  quickCheck prop_other

prop_noTriangle (Positive a) (Positive b) (Positive c) = triangleCombinations a b (a+b+c) NoTriangle
prop_equilateral (Positive a) = triangleCombinations a a a Equilateral
prop_isosceles (Positive a) = triangleCombinations a a (a+1) Isosceles
prop_rectangular (Positive a) = validateRectangular $ pythagoreanTriplets !! a
prop_other (Positive a) = triangleCombinations (a*51) (a*55) (a*5) Other

pythagoreanTriplets :: [[Integer]]
pythagoreanTriplets = generateTriplets 250

generateTriplets :: Integer -> [[Integer]]
generateTriplets n = [ [a,b,c] | a <- [1..n], b <- [1..n], c <- [1..n], (a^2) + (b^2) == (c^2)]

validateRectangular :: [Integer] -> Bool
validateRectangular (a:b:c:[]) = triangleCombinations a b c Rectangular

triangleCombinations :: Integer -> Integer -> Integer -> Shape -> Bool
triangleCombinations a b c expectedType = allOf expectedType $ [triangle a b c, triangle a c b,
                                          triangle b a c, triangle b c a,
                                          triangle c a b, triangle c b a]

allOf :: Eq a => a -> [a] -> Bool
allOf _ [] = True
allOf a (x:xs) = a == x && allOf a xs

triangle :: Integer -> Integer -> Integer -> Shape
triangle a b c = evaluateShape $ sort [a,b,c]

evaluateShape :: [Integer] -> Shape
evaluateShape (a:b:c:[]) | invalidTriangle a b c = NoTriangle
                         | (a == b) && (a == c) = Equilateral
                         | (a^2) + (b^2) == (c^2) = Rectangular
                         | (a == b ) || (a == c) || (b == c) = Isosceles
                         | otherwise = Other
evaluateShape _ = NoTriangle

invalidTriangle :: Integer -> Integer -> Integer -> Bool
invalidTriangle a b c = (a + b < c)

-- Exercise 3a :: Cas' Version
--             :: Time spent: 60 minutes (+ 30 minutes discussion)

exercise3a = do
  print $ compar domain one two
  print $ compar domain one three
  print $ compar domain one four
  print $ compar domain two three
  print $ compar domain three four

stronger, weaker :: [a] -> (a -> Bool) -> (a -> Bool) -> Bool
stronger xs p q = forall xs (\ x -> p x --> q x)
weaker   xs p q = stronger xs q p

one, two, three, four :: Int -> Bool
one = (\x -> even x && x > 3)
two = (\x -> even x || x > 3)
three = (\x -> (even x && x > 3) || even x)
four = (\x -> (even x && x > 3) || even x)

domain :: [Int]
domain = [-10..10]

data PropertyStrength = Stronger | Weaker | Equivalent | Incomparable
  deriving (Eq, Show)

compar :: [a] -> (a -> Bool) -> (a -> Bool) -> PropertyStrength
compar xs p q
  | (stronger xs p q) && (stronger xs q p) = Equivalent
  | stronger xs p q = Stronger
  | stronger xs q p = Weaker
  | otherwise = Incomparable

combcompar x y = compar x (y !! 0) (y !! 1)

instance Ord PropertyStrength where
  compare Stronger Stronger = EQ
  compare Stronger Weaker = GT
  compare Stronger Equivalent = GT
  compare Stronger Incomparable = GT
  compare Equivalent Stronger = LT
  compare Equivalent Equivalent = EQ
  compare Equivalent Weaker = GT
  compare Equivalent Incomparable = GT
  compare Weaker Stronger = LT
  compare Weaker Equivalent = LT
  compare Weaker Weaker = EQ
  compare Weaker Incomparable = GT
  compare Incomparable Stronger = LT
  compare Incomparable Equivalent = LT
  compare Incomparable Weaker = LT
  compare Incomparable Incomparable = EQ

-- Exercise 3b :: Cas' Version
--             :: Time spent: 60 minutes (+ 30 minutes discussion)
exercise3b = do
  print $ sort $ map (combcompar domain) (combinations 2 [one,two,three,four])

combinations :: Int -> [a] -> [[a]]
combinations 0 _  = [ [] ]
combinations n xs = [ y:ys | y:xs' <- tails xs, ys <- combinations (n-1) xs']

-- Exercise 4 :: Joint effort (decided to redo the whole thing)
--            :: Time spent: 90 minutes (redo the whole thing + writing tests)
-- We generate lists we know to be no-permutations.
-- Then, we generate arbitrary lists and validate it against the Haskell library.
-- In order to validate the implementation, run it against the library implementation provided
exercise4 = do
  quickCheck prop_permutation_validate_length
  quickCheck prop_permutation_validate_content
  quickCheckWith stdArgs {maxSize=10} prop_permutation_validate_against_lib

-- Weakest property => validate the length property holds, filtering by this property yields any list of n items
prop_permutation_validate_length :: Positive Integer -> Bool
prop_permutation_validate_length (Positive n) = not $ isPermutation [1..n] [1..n+1]

-- Stronger property => validate content of lists, filtering by this property yields a list
prop_permutation_validate_content :: Positive Integer -> Bool
prop_permutation_validate_content (Positive n) = not $ isPermutation [1..n] [2*n..3*n]

-- Strongest => 1 : 1 comparison against the library.
prop_permutation_validate_against_lib :: [Integer] -> Bool
prop_permutation_validate_against_lib xs = allOf True (map (isPermutation xs) (permutations xs))

isPermutation :: Eq a => [a] -> [a] -> Bool
isPermutation xs ys  =  (length xs == length ys) && null (xs \\ ys)

-- Exercise 5 :: Bauke and Cas' merged versions
--            :: Time spent: 60 minutes (sum of its parts and refactoring/merging)
-- Simply reusing the code for checking a permutation and making it stronger
-- by checking for the unique indexes
-- For the property checking, the same approach as in Exercise 4 is used.
-- First, check some weak properties by generating lists which are known to be invalid.
-- Then, use the permutations generator to verify the implementation using arbitrary lists.

exercise5 = do
  quickCheck prop_derangement_validate_length
  quickCheck prop_derangement_validate_content
  quickCheck prop_derangement_permutations -- Try Counterexamples
  quickCheckWith stdArgs {maxSize=10} prop_derangement_validate_against_lib
  quickCheckWith stdArgs {maxSize=10} prop_derangement_empty_lists

-- Weakest property => validate the length property holds, filtering by this property yields any list of n items
prop_derangement_validate_length :: Positive Integer -> Bool
prop_derangement_validate_length (Positive n) = not $ isDerangement [1..n] [1..n+1]

-- Stronger property => validate content of lists, filtering by this property yields a list
prop_derangement_validate_content :: Positive Integer -> Bool
prop_derangement_validate_content (Positive n) = not $ isDerangement [1..n] [2*n..3*n]

-- Strongest => 1 : 1 comparison against the library.
prop_derangement_validate_against_lib :: [Integer] -> Bool
prop_derangement_validate_against_lib xs = allOf True (map (isDerangement xs) (deran xs))

prop_derangement_empty_lists :: Positive Integer -> Bool
prop_derangement_empty_lists (Positive n) =
  [] == deran [ n | a <- [0..n]]

prop_derangement_permutations :: Positive Integer -> Bool
prop_derangement_permutations (Positive n) =
  not $ (not (isDerangement [1..n] [2*n..3*n]) && (isPermutation [1..n] [2*n..3*n]))

isDerangement :: Eq a => [a] -> [a] -> Bool
isDerangement x y = ((length $ findIndices id $ zipWith (==) x y) == 0) && isPermutation x y

deran :: Eq a => [a] -> [[a]]
deran x = filter (\ y -> isDerangement y x) (permutations x)

-- Exercise 6 :: Merged Version of Bauke and Willem-Jan
--            :: Time spent: 45 minutes (sum of its parts) + 15 minutes refactoring
exercise6 = do
  print $ simpleImplementation
  quickCheck prop_GeneratesSameOutputForSameInput
  quickCheck prop_ReversibleWhenAppliedTwice
  quickCheck prop_MaintainsCase
  quickCheck prop_MaintainsLength
  quickCheck prop_ChangesAllAlphaCharacters
  quickCheck prop_IgnoresAllNonAlphaCharacters

simpleImplementation :: String
simpleImplementation = map rot13 "a simple implementation"

-- Requires generators
-- one could argue that using a random a .. z generator.
-- but even with inifinite tests, 100% coverage is never guaranteed
-- simply mapping the conversion over all available chars will yield guaranteed coverage
prop_ChangesAllAlphaCharacters =
  map id alphaCharacters /= map rot13 alphaCharacters

-- Same for the nonAlpha chars. Simply mapping it to all characters known to be ignored
-- yields 100% coverage.
prop_IgnoresAllNonAlphaCharacters =
  map id nonAlphaCharacters == map rot13 nonAlphaCharacters

nonAlphaCharacters :: [Char]
nonAlphaCharacters = ([(chr 0x20) .. (chr 0x7E)] \\ alphaCharacters)

alphaCharacters :: [Char]
alphaCharacters = ['A'..'Z'] ++ ['a'..'z'] ;

prop_ReversibleWhenAppliedTwice :: String -> Bool
prop_ReversibleWhenAppliedTwice text =
  text == (maskString $ maskString text)

prop_MaintainsCase text =
 (map isLowerCase (maskString text) == map isLowerCase text)
 && (map isUpperCase (maskString text) == map isUpperCase text)

prop_MaintainsLength :: String -> Bool
prop_MaintainsLength text =
  length text == length (maskString text)

prop_GeneratesSameOutputForSameInput :: String -> Bool
prop_GeneratesSameOutputForSameInput text =
  maskString text == maskString text

maskString :: String -> String
maskString input = [ rot13 a | a <- input]

rot13 :: Char -> Char
rot13 c | c `elem` upper = upperRot13 !! fromJust(elemIndex c upper)
        | c `elem` lower = lowerRot13 !! fromJust(elemIndex c lower)
        | otherwise = c

upper, lower, upperRot13, lowerRot13 :: String
upper = ['A'..'Z']
lower = ['a'..'z']
upperRot13 = ['N'..'Z'] ++ ['A'..'M']
lowerRot13 = ['n'..'z'] ++ ['a'..'m']

isLowerCase, isUpperCase :: Char -> Bool
isLowerCase char = ('a' <= char) && ('z' >= char)
isUpperCase char = ('A' <= char) && ('Z' >= char)

-- Exercise 7 :: Merged version of Bauke, Willem-Jan, and Cas
--            :: Time spent: 120 minutes + 60 minutes (discussion/merging)
-- Checking the iban algorithm was fairly easy to implement.
-- For testing, the first idea was to simply shift permutations of the account
-- and make sure those were invalidated. However, this quickly results in valid
-- accounts, since there are a lot of account numbers and only 100 checksums.
-- Therefore, a simple 'invalidator' was used to flip some values and invalidate
-- the ibans provided

exercise7 = do
  print $ forall validIbans iban
  print $ forall (map (invalidateIban 1) validIbans) iban

iban :: String -> Bool
iban account | not $ preCheck account = False
             | otherwise = calculatedNumber account == actualNumber account

preCheck :: String -> Bool
preCheck s = s =~ "^[A-Z]{2}[0-9]{2}[A-Z0-9]{0,30}"

inLimits :: Integer -> (Integer, Integer) -> Bool
inLimits act (min,max) = min <= act && max >= act

calculatedNumber :: String -> Integer
calculatedNumber account = (-) 98 $ flip mod 97 $ read (convertChars $ preProcess account) :: Integer

actualNumber :: String -> Integer
actualNumber (_:_:c1:c2:_) = read ([c1] ++ [c2]) :: Integer

preProcess :: String -> String
preProcess (a:b:_:_:rest) = rest ++ [a] ++ [b]

convertChars :: String -> String
convertChars [] = "00"
convertChars (x:xs) | ('A' <= x) && ('Z' >= x) = (show $ (+) 10 $ (ord x) - (ord 'A')) ++ convertChars xs
                    | otherwise = [x] ++ convertChars xs

shuffleNums :: Int -> Int -> Int
shuffleNums x c
  | (x < 57) && (x >= 48) = (x + c)
  | x == 57 = (x - (10 - c))
  | otherwise = x

invalidateIban :: Int -> String -> String
invalidateIban c x = map chr (map (shuffleNums c) (map ord x))

prop :: String -> Int -> String
prop account n = (accountPermutations account) !! n

accountPermutations :: [Char] -> [[Char]]
accountPermutations account = permutations account

  -- ===========================================================================
  -- The below two quicktest implementations fail, but they also prove a point
  -- ===========================================================================

  -- The below fails, since there are permutations that generate a valid account number
  -- quickCheckResult(\n -> n >= 1 --> iban (prop (invalidateIban 1 "AL47212110090000000235698741") n) == True)
  -- The below ALSO fails, since there are shuffles that generate a valid account number
  -- quickCheckResult(\n -> n >= 1 --> (iban (invalidateIban n "AL47212110090000000235698741")) == True)

-- Bonus Exercises
exercisebonus = do
  putStr "Euler 01, sum all natural numbers up to 1000, dividable by 3 or 5: "
  print $ euler1
  putStr "Euler 29, number of terms: "
  print $ euler29
  putStr "Euler 41, largest pandigital n-digit prime: "
  print $ euler41

euler1 = sum $ [a | a <- [1..999], mod a 3 == 0 || mod a 5 == 0]

-- a ^ b => generates 15 distinct terms for a 2..5 and b 2..5
-- how many terms does a^b generate for a 2 .. 100 and b 2..00
euler29 :: Integer
euler29 = genericLength $ distinctTerms [2..100]

distinctTerms :: [Integer] -> [Integer]
distinctTerms domain = asSet [ a^b | a <- domain, b <-domain ]

euler41 :: Integer
euler41 = pandigitalPrime 9

pandigitalPrime :: Integer -> Integer
pandigitalPrime n
        | null candidates = pandigitalPrime (n - 1)
        | otherwise = maximum candidates
        where
           candidates = [ read n  :: Integer| n <- permutations $ numbers $ map(show) [1..n], prime $ (read n)]
-- Utils
numbers xs = foldr (++) "" xs
charcodes = (zip ['A'..'Z'] [10..35])
readStringInt x = (read x :: Integer)

prime :: Integer -> Bool
prime n = n > 1 && all (\ x -> rem n x /= 0) xs
  where xs = takeWhile (\ y -> y^2 <= n) primes

primes :: [Integer]
primes = 2 : filter prime [3..]

asSet :: Eq a => [a] -> [a]
asSet [] = []
asSet (x:xs) | elem x xs = asSet xs | otherwise = x : asSet xs

-- IBANS :: MOVED HERE TO NOT HAVE A CHUNK OF DATA IN THE MIDDLE OF THE FILE
validIbans :: [String]
validIbans = [
  "AL47212110090000000235698741",
  "AD1200012030200359100100",
  "AT611904300234573201",
  "AZ21NABZ00000000137010001944",
  "BH67BMAG00001299123456",
  "BE62510007547061",
  "BA391290079401028494",
  "BG80BNBG96611020345678",
  "HR1210010051863000160",
  "CY17002001280000001200527600",
  "CZ6508000000192000145399",
  "DK5000400440116243",
  "EE382200221020145685",
  "FO9754320388899944",
  "FI2112345600000785",
  "FR1420041010050500013M02606",
  "GE29NB0000000101904917",
  "DE89370400440532013000",
  "GI75NWBK000000007099453",
  "GR1601101250000000012300695",
  "GL5604449876543210",
  "HU42117730161111101800000000",
  "IS140159260076545510730339",
  "IE29AIBK93115212345678",
  "IL620108000000099999999",
  "IT40S0542811101000000123456",
  "JO94CBJO0010000000000131000302",
  "KW81CBKU0000000000001234560101",
  "LV80BANK0000435195001",
  "LB62099900000001001901229114",
  "LI21088100002324013AA",
  "LT121000011101001000",
  "LU280019400644750000",
  "MK07250120000058984",
  "MT84MALT011000012345MTLCAST001S",
  "MU17BOMM0101101030300200000MUR",
  "MD24AG000225100013104168",
  "MC9320052222100112233M44555",
  "ME25505000012345678951",
  "NL39RABO0300065264",
  "NO9386011117947",
  "PK36SCBL0000001123456702",
  "PL60102010260000042270201111",
  "PT50000201231234567890154",
  "QA58DOHB00001234567890ABCDEFG",
  "RO49AAAA1B31007593840000",
  "SM86U0322509800000000270100",
  "SA0380000000608010167519",
  "RS35260005601001611379",
  "SK3112000000198742637541",
  "SI56191000000123438",
  "ES8023100001180000012345",
  "SE3550000000054910000003",
  "CH9300762011623852957",
  "TN5910006035183598478831",
  "TR330006100519786457841326",
  "AE070331234567890123456",
  "GB86RBOS60161331926819"
  ]
