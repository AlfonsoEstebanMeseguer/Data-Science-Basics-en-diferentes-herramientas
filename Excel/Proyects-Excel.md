The projects that will be carried out below are not applicable to a REAL work scale, they are merely representative of how, to the best of my knowledge, I solve a simple problem using the Excel tool.
# Data cleaning
The dataset in question is a historical list of US presidents taken from an Excel course on basic data cleaning. The data is messy and contains many errors.

The first thing we do is remove duplicates by going to Data > Remove Duplicates and selecting all columns.

The second thing we do is examine the data above each column. As we can see in the 'Presidents' column, several names don't follow a strict spelling rule: JAMES MONROE, Martin Van Buren, John Tyler. For best practices, the first step is to create a new column, 'presidents-fixed,' with the PROPER rule, which establishes the Aa spelling format (always starting with a capital letter followed by lowercase letters).

Next, in the 'party' column (referring to the president's political affiliation), we see that despite being a categorical column, several labels are repeated with different names: Demorcatic, Democratic, among others. To fix this, we go to Data > Filter and merge each label with redundant values ​​into a single value. (In the previous example, everything would be set to Democratic.)

Next, in the vice (vice president) column, we see names with incorrect spacing: John C Calhoun, Millard Fillmore, etc. To fix this, we create another column, 'vice-fixed,' with a TRIM rule that removes duplicate spacing without a defined character.

The 'salary' column is formatted as Text even though it displays numerical data. To format it, we go to Home and change the format. This ensures that the value is 100% numeric when performing mathematical operations.

Additionally, in both the 'date updated' and 'date created' columns, we see that not all dates have the same format. Some are in dd/mm/yyyy format, while others use the day name (Wednesday, July 14). We'll change the column format so that all cells in the Home column use dd/mm/yyyy and change the format to short date.

We'll remove the values ​​from the 'vice' and 'president' columns and replace them with the values ​​from the 'fixed' columns. We'll also remove the 'prior' columns because they don't contribute any relevant value to the dataset.
# Proyect
## Data Cleaning & Worksheet
The following project uses the Kaggle dataset https://www.kaggle.com/code/sadiqshah/bike-store-sales-in-europe, which samples a list of information related to bicycle sales in Europe.

Just as I did in SQL, the first thing we do is copy all the raw data and operate on the copy. As a best practice, you should always operate on a copy and keep the raw data.

As in the simple data cleaning project, we remove duplicates. We also change the format of the 'Income' column because, as mentioned in the previous project, the format is text when it should be numeric to be able to perform mathematical operations with these values.

We also fixed a redundancy issue in the 'Gender' and 'Marital Status' columns, as both used the values ​​M (Married/Male) when their values ​​were different. Therefore, we replaced M with Male in 'Gender' and F with Female in 'Marital Status' using Ctrl+H, and M with Married and S with Single in 'Marital Status'.

I'm going to declare a column that establishes the age range of a user because the goal of this project is to sample the percentage of each age group when buying bicycles. To do this, we created a column and added the following rule:

=IF(L3>55; "Old";IF(L3>=31; "Middle Age"; IF(L3<31;"Adolescent";"Invalid")))

donde L es la columna 'Age'. 
## Pivot Table
We're going to work with Pivot Tables. To do this, go to Insert > Pivot Table, navigate to the tab where you did the previous work in [Data Cleaning & Worksheet], and copy everything using Ctrl+H. Next, I propose answering a series of questions to infer information from the acquired data.

One of these questions could be: 'What is the gender gap when it comes to buying a bicycle?' To do this, I create a pivot table and put gender in the rows, income in the values, and bicycles purchased in the columns. I want to sample the income by average, so I click the down arrow next to the income field and change the representation from SUM to AVERAGE. To better represent this table, we insert a basic column chart. The numerical values ​​for monetary amounts are not entirely correct for presentation purposes. We formatted them as numbers, but the decimal points were incorrect. To correct this, we removed the irrelevant decimal places and added the comma for numbers with more than three digits (1000 euros -> 1,000 euros). The results are consistent, with only a difference of 7,000 more men than women who did buy a bicycle.

Another question could be: 'Which bicycle mileage was the most profitable?' To answer this, we created another pivot table with all the data and entered 'Commute Distance' in the rows and 'Purchased Bikes' in both the columns and values. This way, in addition to providing the values ​​for the 'No' and 'Yes' columns, it also counts them. The most profitable mileage, according to the results, was km-0. The data shows that new bicycles are very profitable and in high demand.

The final question to be asked was which age range had the greatest influence on rental income. We'll do this in two ways: with all ages and with the previously calculated 'Age Brackets' field. To do this, we'll again create two pivot tables. In both, we'll use 'Purchased Bikes' as both columns and values ​​to count the results, but in one table, we'll use 'Age Brackets' as rows and in the other, 'Age'. Thanks to these two pivot tables, we can understand why it was necessary to declare age ranges. It's very difficult to estimate results with ALL the ages present in the dataset; however, thanks to this field, we can clearly see that the third age group (31-54) dominates bicycle purchases.
## Dashboard
All Excel work should be represented visually. To do this, for each declared Pivot Table, we go to Insert > Recommended Chart and choose the chart to our liking. To visualize/filter data in real time, for each chart we go to PivotChart Analyze > Insert Slicer and place the sliding window to filter the charts.