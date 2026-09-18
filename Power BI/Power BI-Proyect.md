Like the rest of the projects in this set of basic training skills in data engineering, this work is not applicable in a real environment, it is merely representative and seeks to solve/induce/answer a series of questions that could be asked about a data set using simple tools provided by the application, specifically Power BI.
# Dataset
The dataset is a questionnaire administered to a large number of users in the IT field. In addition to collecting data such as email addresses (which can be left anonymous with the 'anonymous' option) and the date the questionnaire was administered, it also includes a list of questions such as, "What country do you live in?", "What programming language do you use?", "If you had to look for a job today, what would be the most important thing for you?", etc. The questionnaire was provided by a GitHub repository dedicated to Power BI basics: https://github.com/AlexTheAnalyst/Power-BI/blob/main/Power%20BI%20-%20Final%20Project.xlsx
# Data Cleaning with Power Query Editor
The first thing we'll do with the database is clean the data from the Excel workbook using the Power Query editor. The data is transformed from the editor and imported into the Power BI environment, so there's no need to make a copy of the raw data from the Excel workbook.
## Empty Columns
The first thing is to remove empty columns. In this dataset, we see that the columns 'Browser', 'OS', 'City', 'Country', and 'Referrer' have hardly been answered. It's difficult to induce ideas with such a scarcity of data, and they take up a lot of space. I'm going to remove those four columns.
## Standarize Labels
The second step is to standardize the amount of labeling. There are two questions that we will consider extensively for the next stage of the project:
- Q1 - Which Title Best Fits Your Current Role?
- Q4 - What Industry do you work in?
However, it's difficult to create graphs with so many labels; they are not very representative. In other words, Q1 has labels like Data Analyst, Data Engineer, Data Scientist, etc. But it also has an 'Other' field with different types: Other (Please Specify): Analyst, Other (Please Specify): BI Developer, Other (Please Specify): Ads operation, etc.

These values, even though they are specific, won't be useful for the visualization because we won't be working with the specificity of the jobs. Furthermore, the project will revolve around the main labels (Data Analyst, Data Engineer, Data Scientist, etc.). This is repeated in Q4, Q5, and Q11.

To remove these redundant values, go to Home > Split Column > Custom character and type '('. Two columns will then be formed, one with the data before '(' and another with the data after '('. Since we don't need the latter data, we'll delete that column.
## Average Salary
For this task, the salary range (Question Q3) of the specific user is sampled in 'Text' format, marking thousands with 'k', for example: 15k-75k. However, we cannot work with this data in 'Text' format, and instead of this range, we could calculate the average salary for each employee and infer information from it.

To do this, we duplicate column Q3 (I want to maintain the salary range but work with the average salary) and in this column, we select Home > Split Column > Digit to not Digit. This operation separates the numeric values. Next, we delete the column with trailing 'k's. For the two remaining columns, we replace the 'k's with nothing to remove them from the column. Finally, there is a case where the salary is 255k+, meaning without a limit. We replace the '+' value with '255' to minimize calculation errors.

At this point in the project, we'll have two columns: the first with the minimum salary range and the second with the maximum salary range. We convert these values ​​to integers and add a column using Add Column > Custom Column. We name it `Average Salary` and create the field by calculating (column_minimum_salary_range + column_maximum_salary_range) / 2. This column allows us to work with the minimum salary.

The dataset is now ready for visualization.
# Data visualization with Power BI
Next, I will answer a set of questions that can be inferred from the data in the dataset. Decorative aspects are ignored.

**1. Representation of the countries from which the survey was conducted**
To answer this question: we plotted a 'TreeMap' chart and added 'Q11-Which country do you live in?' to the 'Category' field. We then added the same value to the chart's legend to color each country differently. The result is that the survey was dominated by the following countries: the United States, India, and Canada.

**2. Average salary by job title**
To answer this question: we plotted a bar chart and on the Y-axis we put 'Q1-Which title best fits your current role?' and on the X-axis we put the 'Average Salary' field, calculated during data cleaning. To differentiate the legend, we dragged 'Q1-Which title best fits your current role?' to color different job titles. The result is that data scientists earn a salary of around $100,000 a year, making them the highest paid, while students barely earn $20,000 a year.

**3. Happiness with Salary**
To answer this question: we plotted a 'Gauge' chart and in the 'Value' field we added 'Q6-How happy are you in your current position with the following? (Salary)' and entered the same resource in the 'Min' and 'Max' fields, using the minimum and maximum values ​​for that field. The result is 4.27/10, which makes sense since the IT field is increasingly undervalued in the job market.

**4. Happiness with Work-Life Balance**
To answer this question: we plotted a 'Gauge' chart and in the 'Value' field we added 'Q6-How happy are you in your current position with the following? (Work/Life Balance) and we put the same resource in the 'Min' and 'Max' fields with the minimum and maximum values ​​for that field. The result is a happiness score of 5.74 out of 10, a somewhat low value.

**5. How difficult was it to access the data sector?**
To answer this question: we plotted a 'Donut Chart' and in both the legend and the 'Values' field we put 'Q7 - How difficult was it to Break into Data Science', in the case of 'Values' (value per count). The result was that for most people (42%), it was neither easy nor difficult.

**6. Favorite Programming Language**
To answer this question: we plotted a bar chart and on the X-axis we put 'Q5-Favorite Programming Language' and on the Y-axis 'Unique ID' (by count). Power BI's job is to look at the programming language for each ID and recount them, creating a bar chart. We can add more value to the chart by including 'Q1-Which title best fits your current role?' in the legend, so that each worker role is colored differently. The most used language by far is Python, which is very consistent with reality, as it is the most used language in big data environments.

**7. Number of Respondents and Average Age**
**Average Age**
To answer this question: we plotted a card chart and in the field we put 'Current Q10 - Age' and in the field option we selected to calculate the average. The result is an average age of 30 years.

**Number of Respondents**
To answer this question: we plotted a card-type chart and in the field we entered 'Unique ID'. In the field's option, we selected to calculate the weighted count, not the sum or the average. The result is 630 respondents.