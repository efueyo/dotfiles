(
 [
  (interpreted_string_literal) (raw_string_literal)
 ] @sql
 (#match? @sql "(SELECT|DELETE).*FROM|(CREATE|DROP) TABLE|INSERT INTO|UPDATE.*SET.*FROM")
 ; offset to remove the " or ` characters
 (#offset! @sql 0 1 0 -1)
)

