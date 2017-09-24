module Lab3.Final.Exercises where

import Data.List

import Lab3.Lecture3

import System.Random

import Test.QuickCheck
import Test.QuickCheck.Monadic

-- Define Main --
main = do
    putStrLn $ "===================="
    putStrLn $ "Assignment 3 / Lab 3"
    putStrLn $ "===================="
    putStrLn $ "> Exercise 1"
    exercise1
    putStrLn $ "> Exercise 2"
    exercise2
    putStrLn $ "> Exercise 3"
    exercise3
    putStrLn $ "> Exercise 4"
    -- exercise4
    putStrLn $ "> Exercise 5"
    -- exercise5

-- | Exercise 1
-- Time spent: 2 hours
-- The implementation mimics as one who would manually check the properties.
-- Writing a new formula above a truth table and evaluation all values of the forms being compared.
-- Then checking, for entailment / equivalence if all values are 'true'
-- We use the forms from Lecture3.hs to check some basic properties of the functions
-- We noticed that for some of our own implementations we simply checked the valuations.
-- This exposed some issues, since two forms can have different input variables.
-- Some implementations were incompatible with different list sizes, furthermore for equal valuation sizes,
-- equal variable names were assumed. Added two explicit test cases which exposed this issue.

exercise1 = do
  putStr "contradictionTest: "
  print contradictionTest
  putStr "tautology: "
  print tautologyTest
  putStr "entails: "
  print entailsTest
  putStr "equivalence: "
  print equivalenceTest
  putStr "Bug fixed with regard to different sizes: "
  print $ True == showSizeIssue
  putStr "Bug fixed with regard to different names: "
  print $ False == showNameIssue

-- | logical contradiction
-- No set of values exists where the form returns true, so if we cannot find a
-- satisfiable set of values the form is a contradiction
contradiction :: Form -> Bool
contradiction f = not $ satisfiable f

-- | logical tautology
-- Instead of finding one set of values which make the form return true like in satisfiable,
-- it should return true for all sets of values
tautology :: Form -> Bool
tautology f = all (`evl` f) (allVals f)

-- | logical entailment
-- When the first form returns true, and the second form returns true, we return true,
-- this is an implication which we should check for every set of values, thus a tautology
entails :: Form -> Form -> Bool
entails f1 f2 = tautology (Impl f1 f2)

-- | logical equivalence
-- Each set of values should return the same value for both forms,
-- which means we can define an equivalence relation,
-- and this should return true for every set of values, so it should be a tautology
equiv :: Form -> Form -> Bool
equiv f1 f2 = tautology (Equiv f1 f2)

-- | Used to expose bug with entailment for different list sizes
showSizeIssue = doEntail "*(1 2)" "+(*(1 2) 3)"

-- | Used to expose bug with entailment for different variable names
showNameIssue = doEntail "*(1 2)" "*(3 4)"

doEntail :: String -> String -> Bool
doEntail f1 f2 = entails (doParse f1) (doParse f2)

doParse :: String -> Form
doParse = head . parse

-- Test contradiction
contradictionTest, tautologyTest, entailsTest, equivalenceTest :: Bool
contradictionTest =  (contradiction form1 == False)
                  && (contradiction form2 == False)
                  && (contradiction form3 == False)

tautologyTest =  (tautology form1 == True)
              && (tautology form2 == False)
              && (tautology form3 == True)

entailsTest =  (entails form1 form1 == True)
            && (entails form1 form2 == False)
            && (entails form1 form3 == True)
            && (entails form2 form1 == True)
            && (entails form2 form2 == True)
            && (entails form2 form3 == True)
            && (entails form3 form1 == True)
            && (entails form3 form2 == False)
            && (entails form3 form3 == True)

equivalenceTest =  (equiv form1 form1 == True)
                && (equiv form1 form2 == False)
                && (equiv form1 form3 == True)
                && (equiv form2 form1 == False)
                && (equiv form2 form2 == True)
                && (equiv form2 form3 == False)
                && (equiv form3 form1 == True)
                && (equiv form3 form2 == False)
                && (equiv form3 form3 == True)


-- | Exercise 2
-- Time spent: approximately 3 hours
-- The 'happy day' scenario was tested using a random form generator.
-- All these forms should be eating by the parser and should return a non-empty list
-- When showing the parsed form back to the console, they should be equivalent to the input
-- Generating counter examples proved to be difficult, since the parser exposed different behaviour
-- for different kind of errors.
-- One would expect the parser to return just the form for correct input or nothing at all for incorrect input.
-- Perhaps a nice approach for this would be to have a signature Maybe Form
-- This also allows for parsing an empty string, knowing it is valid tautology, instead of spreading false results
-- Due to parsing partially correct data
-- Generate a form => should pick an operator and then form
-- Time spent: 90 minutes on generator due to issues with the IO type.
-- Looked up the examples from the previous labs and used that to concatenate the strings
-- Looked up a way to check IO data with normal data
-- Time spent: additional 120 minutes on getting the stuff to work with quickCheck.
-- However, this was a useful quest on getting familiar with the monadic stuff.
-- missing IO stuff with non IO stuff can be simply done by binding them in an do statement.
-- nonMonadic <- monadicVersion
-- Alternatively via a lambda: someMonadicStuff = monad >>= (\nonMonadic -> return doStuff nonMonadic)

exercise2 = do
  quickCheck prop_sensibleData
  quickCheck prop_unchanged

-- All terms randomly generated parse to a non-empty list
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

-- | Picks a random item from the list passed
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

-- | This partial result only returns the first term. the implication to the second is missing
partialResultForMissingBrackets = doParse "(1==>2) ==> (1==>3)"

-- | When invalid tokens are received, an exception is thrown
exceptionForIncorrectTokens = doParse "(1<==>3)"

-- | Empty list for tokens which are all partial
emptyListForPartialTokens = parse "((1 2) (3 4))"

-- =============================================================================
-- Exercise 3 :: Time spent more than 12 hours! spent
-- We have implemented two ways, the 'traditional way' using the truth tables as demonstrated during the workshop
-- The other way uses a four-way conversion described in the link:
-- http://homepage.cs.uiowa.edu/~tinelli/classes/188/Fall10/notes/cnf-conversion.pdf
-- We use both ways and verify them against each other and the original
-- For test input we used the wikiPedia examples which were known to be nnf
-- Tested by verifying the truth tables and the String forms are unmatched
-- =============================================================================
wiki1, wiki2, wiki3 :: String
wiki1 = "-+(1 2)"
wiki2 = "+(*(1 2) 3)"
wiki3 = "*(1 *(+(2 3) +(2 5)))"

exercise3 = do
  putStr "Checking results for wiki1: "
  print $ checkResults wiki1
  putStr "Checking results for wiki2: "
  print $ checkResults wiki2
  putStr "Checking results for wiki3: "
  print $ checkResults wiki3

checkResults :: String -> Bool
checkResults str = equiv' [f , convertTraditional f, convertNonTraditional f]
  where f = doParse str

-- | Simple equivalence checker for list of forms
equiv' :: [Form] -> Bool
equiv' (f1:f2:[]) = equiv f1 f2
equiv' (f1:f2:fs) = (equiv f1 f2) && (equiv' (f2:fs))


-- | Traditional using using the truth tables
convertTraditional :: Form -> Form
convertTraditional = doParse . convertToCNF . invertLiterals . getNonTruths . nnf . arrowfree

convertToCNF :: [Valuation] -> String
convertToCNF v = andCNF (map ordCNF v)

andCNF :: [String] -> String
andCNF (x:xs)
  | length xs < 2 = "*(" ++ x ++ " " ++ xs !! 0 ++ ")"
  | otherwise = "*(" ++ x ++ " " ++ andCNF xs ++ ")"

ordCNF :: Valuation -> String
ordCNF (x:xs)
  | length xs < 2 && snd x == True && snd (xs !! 0) == True = "+(" ++ show (fst x) ++ " " ++ show (fst (xs !! 0)) ++ ")"
  | length xs < 2 && snd x == False && snd (xs !! 0) == True = "+(-" ++ show (fst x) ++ " " ++ show (fst (xs !! 0)) ++ ")"
  | length xs < 2 && snd x == True && snd (xs !! 0) == False = "+(" ++ show (fst x) ++ " -" ++ show (fst (xs !! 0)) ++ ")"
  | length xs < 2 && snd x == False && snd (xs !! 0) == False = "+(-" ++ show (fst x) ++ " -" ++ show (fst (xs !! 0)) ++ ")"
  | length xs >= 2 && snd x == False = "+(-" ++ show (fst x) ++ " " ++ ordCNF xs ++ ")"
  | otherwise = "+(" ++ show (fst x) ++ " " ++ ordCNF xs ++ ")"

invertLiterals :: [Valuation] -> [Valuation]
invertLiterals v = map invertLiteral v

invertLiteral :: Valuation -> Valuation
invertLiteral v = map revert v

-- Revert Valuations
revert :: (Name,Bool) -> (Name,Bool)
revert (k,v) = if v == True then (k,False) else (k,True)

-- This actually returns all valuations for False
getNonTruths :: Form -> [Valuation]
getNonTruths f = filter (\ v -> not $ evl v f) (allVals f)

-- | Implementation using the four steps provided by the link
convertNonTraditional :: Form -> Form
convertNonTraditional = cnf . nnf . arrowfree

cnf :: Form -> Form
cnf  = cnf' . nnf . arrowfree

cnf' :: Form -> Form
cnf' (Prop x) = Prop x
cnf' (Neg (Prop x)) = Neg (Prop x)
cnf' (Cnj fs) = Cnj (map cnf' fs)
cnf' (Dsj fs)
      | not.null $ filter (filterDsj) fs  = cnf' $ Dsj ((liftDsj fs) ++ (filter (not.filterDsj) fs))
      | not.null $ filter (filterCnj) fs  = cnf' (distribute (uniqueMap cnf' fs))
      | otherwise = Dsj (uniqueMap cnf' fs)
    where
        liftDsj fs = nub $ concatMap (\(Dsj xs) -> map (\y -> y ) xs)   (filter (filterDsj) fs)

filterDsj (Dsj x) = True
filterDsj _ = False

filterCnj (Cnj x) = True
filterCnj _ = False

filterProps (Prop x) = True
filterProps _ = False

distribute fs = Cnj expand'
    where
        cnjs = (filter filterCnj fs)
        notConj = (filter (not.filterCnj)) fs
        combineCnj = sequence (map (\(Cnj x) -> x) cnjs)
        expand' = map (\cnjList ->  Dsj (nub (notConj ++ cnjList))) combineCnj


uniqueMap f xs = ys
        where
            ys = nub $ map f xs

