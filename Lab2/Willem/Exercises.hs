module Lab2 where

import Data.List
import Test.QuickCheck
import Data.Bits
import System.Random
import Control.Monad
import Control.Applicative
import Data.Char

-- Assignment 2 / Lab 2 :: Group 14 --

-- Define Main --
main = do
    putStrLn "===================="
    putStrLn "Assignment 2 / Lab 2"
    putStrLn "===================="
    putStrLn "> Exercise 1"
    exercise1
    putStrLn "> Exercise 2"
    exercise2
    putStrLn "> Exercise 3a"
    exercise3a
    putStrLn "> Exercise 3b"
    exercise3b
    putStrLn "> Exercise 4"
    exercise4
    putStrLn "> Exercise 5"
    exercise5
    putStrLn "> Exercise 6"
    exercise6
    putStrLn "> Exercise 7"
    exercise7
    putStrLn "> BONUS"
    exercisebonus

-- provided
infix 1 -->
(-->) :: Bool -> Bool -> Bool
p --> q = not p || q

probs :: Int -> IO [Float]
probs 0 = return []
probs n = do
             p <- getStdRandom random
             ps <- probs (n-1)
             return (p:ps)

-- Exercise 1
-- About one hour also to think of chi test
quartile :: Float -> Float -> Float -> Bool
quartile min max n = n >= min && n < max

quartile1, quartile2, quartile3, quartile4 :: Float -> Bool
quartile1 = quartile 0 0.25
quartile2 = quartile 0.25 0.5
quartile3 = quartile 0.5 0.75
quartile4 = quartile 0.75 1

chi :: Int -> Int -> Float
chi x m = fromIntegral((x-m)^2) / fromIntegral m


distribution :: Int -> IO ()
distribution n = do
                    p <- probs n
                    let a = length $ filter quartile1 p
                    let b = length $ filter quartile2 p
                    let c = length $ filter quartile3 p
                    let d = length $ filter quartile4 p
                    let m = div n 4
                    let x = chi a m + chi b m + chi c m + chi d m
                    print (a,b,c,d,x)

exercise1 = distribution 10000

-- Exercise 2
-- Encoded properties for each triangle
-- 15 min
exercise2 = print()
data Shape = NoTriangle | Equilateral
            | Isosceles  | Rectangular | Other deriving (Eq,Show)

triangle :: Integer -> Integer -> Integer -> Shape
triangle a b c | noTriangle a b c = NoTriangle
               | equilateral a b c = Equilateral
               | isosceles a b c = Isosceles
               | rectangular a b c = Rectangular
               | otherwise = Other

isTriangle, noTriangle, equilateral, isosceles, rectangular :: Integer -> Integer -> Integer -> Bool
isTriangle a b c = (a + b > c) || (a + c > b) || (b + c > a)
noTriangle a b c = not $ isTriangle a b c
equilateral a b c = (a == b) && (a == c) && (b == c)
isosceles a b c = (a == b) || (a == c) || (b == c)
rectangular a b c = (a^2+b^2) == c^2 || (a^2+c^2) == b^2 || (b^2+c^2) == a^2

-- Exercise 3a
exercise3a = print()

-- Exercise 3b
exercise3b = print()

-- Exercise 4
exercise4 = print()

-- Exercise 5
exercise5 = print()

-- Exercise 6
exercise6 = print()

-- Exercise 7
exercise7 = print()

-- Bonus Exercises
exercisebonus = print()
