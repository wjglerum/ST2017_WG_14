module Exercises where

import Control.Monad

import Lab3.Lecture3

import System.Random

import Test.QuickCheck
import Test.QuickCheck.Monadic


exercise1 = do
  putStr "alwaysTrue is a tautology: "
  print $ tautology alwaysTrue
  putStr "neverTrue is a contradiction: "
  print $ contradiction alwaysFalse
  putStr "alwaysTrue is equivalent to itself: "
  print $ equiv alwaysTrue alwaysTrue
  putStr "neverTrue is also equivalent to itself"
  print $ equiv alwaysFalse alwaysFalse

-- | Exercise 1, Give the definitions for the predicates
-- | Time spent: 30 minutes
-- | Most simple thing what works is checking the definitions against predicates which are always true or always false.
-- | Examples: A OR not A => always true. A AND not A => never true

-- | There is no set of values for which the form returns true
contradiction :: Form -> Bool
contradiction form = not $ satisfiable form

-- | There is no set of values for which the form returns false
tautology :: Form -> Bool
tautology f = all (\v -> evl v f) (allVals f)

-- | logical entailment
entails :: Form -> Form -> Bool
entails form1 form2 = isEntailment (allResults form1, allResults form2)

isEntailment :: ([Bool],[Bool]) -> Bool
isEntailment ([],[]) = True
isEntailment ((x:xs),(y:ys)) | x && (not y) = False
                             | otherwise = isEntailment (xs,ys)
-- | logical equivalence
equiv :: Form -> Form -> Bool
equiv form1 form2 = allResults form1 == allResults form2

allResults :: Form -> [Bool]
allResults form = map (flip evl form) (allVals form)

-- | some testSamples
alwaysTrue, alwaysFalse :: Form
alwaysTrue = head $ parse "+(1 -1)"
alwaysFalse = head $ parse "*(1 -1)"

nestedExpression = head $ parse "(+(1 -1) ==> 2)"
ambiguity1 = head $ parse "+(-31)"
ambiguity2 = head $ parse "+( 3 1)"

-- | Exercise 2 - Random text generator for parser
-- | Generate a form => should pick an operator and then form
-- | Time spent: 90 minutes on generator due to issues with the IO type.
-- | Looked up the examples from the previous labs and used that to concatenate the strings
-- | Looked up a way to check IO data with normal data
-- | test link: https://hackage.haskell.org/package/QuickCheck-2.10.0.1/docs/Test-QuickCheck-Monadic.html

-- | Time spent: additional 120 minutes on getting the stuff to work with quickCheck.
-- | However, this was a useful quest on getting familiar with the monadic stuff.

-- | mising IO stuff with non IO stuff can be simply done by binding them in an do statement.
-- | nonMonadic <- monadicVersion
-- | Alternatively via a lambda: someMonadicStuff = monad >>= (\nonMonadic -> return doStuff nonMonadic)

exercise2 = do
  quickCheck prop_sensibleData
  quickCheck prop_unchanged

-- All terms randomly generated should be parseable
prop_sensibleData = monadicIO $ do
  formData <- run parseRandom
  assert ([] /= formData)

-- All parsed terms can be 'shown' => they should be 1 : 1
prop_unchanged = monadicIO $ do
  (str, result) <- run parseIO
  assert (str == (show $ head $ result))

parseIO :: IO (String, [Form])
parseIO = do
  form <- randomForm
  putStr "Parsing: "
  putStrLn form
  return $ (form, parse form)

parseRandom :: IO [Form]
parseRandom = do
              form <- randomForm
              putStr "Parsing: "
              putStrLn form
              return $ parse form

randomForms :: Integer -> IO [String]
randomForms n = sequence [ randomForm | a <- [1..n]]

-- | either a literal or a term
randomTerm :: IO String
randomTerm = do
            n <- randomInteger [0,1]
            l1 <- signedLiteral
            f1 <- randomForm
            if(0 == n)
              then return f1
              else return l1

randomForm :: IO String
randomForm = do
              oper <- randomOperator
              generateForm oper

generateForm :: String -> IO String
generateForm "*" = composeTuple "*" "" >>= (\t -> return t)
generateForm "+" = composeTuple "+" "" >>= (\t -> return t)
generateForm "==>" = composeTuple "" "==>" >>= (\t -> return t)
generateForm "<=>" = composeTuple "" "<=>" >>= (\t -> return t)
generateForm _ = return "INVALID"

-- | Composes random signed literal with random sign of total composition
composeTuple :: String -> String -> IO String
composeTuple pre "" = composeTuple pre " "
composeTuple pre mid = do
                       s1 <- randomSign
                       t1 <- signedLiteral
                       t2 <- signedLiteral
                       return $ s1 ++ pre ++ "(" ++ t1 ++ mid ++ t2 ++ ")"


-- | Random literal with random sign bit
signedLiteral :: IO String
signedLiteral = do
              s <- randomSign
              l <- randomLiteral
              return $ s ++ l

randomOperator, randomSign, randomLiteral :: IO String
randomOperator = randomFrom operators
randomSign = randomFrom signs
randomLiteral = randomFrom literals

-- | Picks a random item from the list
randomFrom :: Eq a => [a] -> IO a
randomFrom xs = randomInteger xs >>= (\randIndex -> return (xs !! randIndex))

randomInteger :: Eq a => [a] -> IO Int
randomInteger xs = (randomRIO (0, (length xs)-1))

operators :: [String]
operators = ["+", "*","==>","<=>"]

signs :: [String]
signs = ["", "-"]

literals :: [String]
literals = [ show a | a <- [1..5]]

-- | Exercise 3 - Convert Formulas into CNF
-- | Simply convert to arrowFree and then nnf


exercise3 = do
  quickCheck prop_wiki1
  quickCheck prop_wiki2
  quickCheck prop_wiki3

prop_wiki1 = checkSample wikiSample1
prop_wiki2 = checkSample wikiSample2
prop_wiki3 = checkSample wikiSample3

checkSample str = (equiv f cnf) && (f /= cnf)
  where f = doParse str
        cnf = convert2cnf f

convert2cnf :: Form -> Form
convert2cnf = nnf . arrowfree

wikiSample1 = "-+(1 2)"
wikiSample2 = "+(*(1 2) 3)"
wikiSample3 = "*(1 *(+(2 3) +(2 5)))"

doParse :: String -> Form
doParse = head . parse

-- | Exercise 4 - Random form generator

-- | Exercise 5 - Bonus Exercise
-- | Time spent: 20 minutes => no useful output, just playing with the Forms to check how to fix it

type Clauses = [Clause]
type Clause = [Int]

alwaysTrueResult, alwaysFalseResult :: Clauses
alwaysTrueResult = [[1, -1]]
alwaysFalseResult = [[1],[-1]]
nestedExpressionResult = [[1, -1], [2]]

wiki1Input, wiki2Input, wiki3Input :: Form
wiki1Input = doParse "+(-2 -3)"
wiki2Input = doParse "*(+(1 3) +(2 3))"
wiki3Input = doParse "*(1 *(+(2 4) +(2 5)))"

wiki1Result, wiki2Result, wiki3Result :: Clauses
wiki1Result = [[-2, -3]]
wiki2Result = [[1, 3], [2, 3]]
wiki3Result = [[1], [2, 3], [2, 5]]

exercise5 = do
  putStr "alwaysTrue in CNF: "
  print $ alwaysTrueResult == (cnf2cls alwaysTrue)
  putStr "alwaysFalse in CNF: "
  print $ alwaysFalseResult == (cnf2cls alwaysFalse)

convertString :: String -> Clauses
convertString = cnf2cls . doParse

cnf2cls :: Form -> Clauses
cnf2cls (Dsj (f1:f2:[])) | (isLiteral f1) && (isLiteral f2) = [(convertLiteral f1) ++ (convertLiteral f2)]
                         | (isLiteral f1) = [(convertLiteral f1)] ++ (convertForm f2)
                         | otherwise = (convertForm f1) ++ (convertForm f2)

cnf2cls (Cnj (f1:f2:[])) | (isLiteral f1) && (isLiteral f2) = [convertLiteral f1, convertLiteral f2]
                         | otherwise = undefined

convertLiteral :: Form -> Clause
convertLiteral (Prop a) = [a]
convertLiteral (Neg (Prop a)) = [-1 * a]
convertLiteral _ = []

convertForm :: Form -> Clauses
convertForm _ = undefined

isLiteral :: Form -> Bool
isLiteral (Prop _) = True
isLiteral (Neg (Prop _)) = True
isLiteral _ = False




