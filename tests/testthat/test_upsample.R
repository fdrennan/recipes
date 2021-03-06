library(testthat)
library(recipes)
library(dplyr)

iris2 <- iris[-(1:45),]
iris2$Species[seq(6, 96, by = 5)] <- NA
iris2$Species2 <- sample(iris2$Species)
iris2$Species3 <- as.character(sample(iris2$Species))

rec <- recipe( ~ ., data = iris2)

test_that('basic usage', {
  rec1 <- rec %>%
    step_upsample(matches("Species$"))
  
  untrained <- tibble(
    terms = "matches(\"Species$\")"
  )
  
  expect_equivalent(untrained, tidy(rec1, number = 1))
  
  rec1_p <- prep(rec1, training = iris2, retain = TRUE)
  
  trained <- tibble(
    terms = "Species"
  ) 
  
  expect_equal(trained, tidy(rec1_p, number = 1))
  
  tr_xtab <- table(juice(rec1_p)$Species, useNA = "always")
  te_xtab <- table(bake(rec1_p, newdata = iris2)$Species, useNA = "always")
  og_xtab <- table(iris2$Species, useNA = "always")
  
  expect_equal(max(tr_xtab), max(og_xtab))
  expect_equal(sum(is.na(juice(rec1_p)$Species)), max(og_xtab))
  expect_equal(te_xtab, og_xtab)
  
  expect_warning(prep(rec1, training = iris2))
})

test_that('ratio value', {
  rec2 <- rec %>%
    step_upsample(matches("Species$"), ratio = .25)
  
  rec2_p <- prep(rec2, training = iris2, retain = TRUE)
  
  tr_xtab <- table(juice(rec2_p)$Species, useNA = "always")
  te_xtab <- table(bake(rec2_p, newdata = iris2)$Species, useNA = "always")
  og_xtab <- table(iris2$Species, useNA = "always")
  
  expect_equal(min(tr_xtab), 10)
  expect_equal(sum(is.na(juice(rec2_p)$Species)), 
               sum(is.na(iris2$Species)))
  expect_equal(te_xtab, og_xtab)
})


test_that('no skipping', {
  rec3 <- rec %>%
    step_upsample(matches("Species$"), skip = FALSE)
  
  rec3_p <- prep(rec3, training = iris2, retain = TRUE)
  
  tr_xtab <- table(juice(rec3_p)$Species, useNA = "always")
  te_xtab <- table(bake(rec3_p, newdata = iris2)$Species, useNA = "always")
  og_xtab <- table(iris2$Species, useNA = "always")
  
  expect_equal(max(tr_xtab), max(og_xtab))
  expect_equal(te_xtab, tr_xtab)
})



test_that('bad data', {
  expect_error(
    rec %>%
      step_upsample(Sepal.Width) %>%
      prep(retain = TRUE)
  )
  expect_error(
    rec %>%
      step_upsample(Species3) %>%
      prep(stringsAsFactors = FALSE, retain = TRUE)
  ) 
  expect_error(
    rec %>%
      step_upsample(Species, Species2) %>%
      prep(stringsAsFactors = FALSE, retain = TRUE)
  )    
})

test_that('printing', {
  rec4 <- rec %>%
    step_upsample(Species)
  
  expect_output(print(rec))
  expect_output(prep(rec4, training = iris2, retain = TRUE, verbose = TRUE))
})

