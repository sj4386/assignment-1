#library(tidyverse)
#library(ellmer)
#library(dotenv)

load_dot_env()

issue_values <- c(
  "Incorrect information on your report",
  "Improper use of your report",
  "Problem with a company's investigation into an existing problem"
)

sub_issue_values <- c(
  "Information belongs to someone else",
  "Credit inquiries on your report that you don't recognize",
  "Reporting company used your report improperly",
  "Account information incorrect",
  "Their investigation did not fix an error on your report",
  "Account status incorrect",
  "Investigation took more than 30 days"
)

structured_outputs <- type_object(
  issue = type_enum(issue_values, required = TRUE),
  sub_issue = type_enum(sub_issue_values, required = TRUE)
)

fallback_value <- list(
  issue = "Incorrect information on your report",
  sub_issue = "Account information incorrect"
)

input <- read_csv("data/input.csv", show_col_types = FALSE)
system_prompt <- read_file("src/prompt.md")

chat <- chat_openai(
  model = "gpt-4.1-nano",
  system_prompt = system_prompt
)

predictions <- parallel_chat_structured(
  chat,
  prompts = as.list(input$consumer_complaint_narrative),
  type = structured_outputs,
  on_error = "return"
)

output <- cbind(input, predictions)
output$issue[is.na(output$issue)] <- fallback_value$issue
output$sub_issue[is.na(output$sub_issue)] <- fallback_value$sub_issue
output <- output[, c("id", "issue", "sub_issue")]
View(output)

write_csv(output, "data/output.csv")

message(sprintf("Wrote %d rows to data/output.csv", nrow(output)))