# Dataset
The dataset to be used is from Kaggle: https://www.kaggle.com/datasets/airbnb/seattle. This dataset contains three .csv files (listings, reviews, and calendar). The dataset contains a comprehensive list of activities related to the entire Airbnb industry in Seattle, WA, since 2008.

# Import problems with Excel
## (.csv) VERY Large
To work with Tableau, we want to import an Excel workbook containing the three pages corresponding to the three .csv files of the dataset. However, the last file, named calendar.csv, contains more rows than can fit on a single Excel sheet. To address this, we'll perform a slicer.

We import the data from Data > Import Files. When loading the data, we transform it and filter by date. On one sheet, we import all the calendar data up to and including April 8, 2016. On another sheet, we repeat the process, filtering the date to include all data from that date onward.

Once we have calendar(2) and calendar(3) in .csv format, we save the entire Excel workbook and open Tableau. Here in the data source section, we might think the best option is to enter `calendar(2)` (or `calendar(3)`) and click it to enter the joins section to perform a full join between `calendar(2)` and `calendar(3)` with the `Listing id` identifier, and then perform an inner join with `listings`. The main goal of this project is to work with ALL the dates in the property listing.

However, this isn't correct because the full join between `calendar(2)` and `calendar(3)` doesn't combine the rows; it searches for matches with the same identifier. The property listing contains hundreds of identifiers for a single property, but if a property is rented or leased multiple times in `calendar`, it will appear with the same identifier but different dates. Therefore, the horizontal full join, instead of combining the rows, will create all the combinations. Let's illustrate this.

**Table A (`calendar_2`)**

|**listing_id**|**date**|**price**|
|---|---|---|
|**101**|2026-01-01|50|
|**101**|2026-01-02|55|
**Table B(`calendar_3`)**

|**listing_id**|**date**|**price**|
|---|---|---|
|**101**|2026-07-01|60|
|**101**|2026-07-02|65|

**Full join `calendar_2` y `calendar_3`**

| **calendar_2.listing_id** | **calendar_2.date** | **calendar_2.price** | **calendar_3.listing_id** | **calendar_3.date** | **calendar_3.price** |
| ------------------------- | ------------------- | -------------------- | ------------------------- | ------------------- | -------------------- |
| **101**                   | 2026-01-01          | 50                   | **101**                   | 2026-07-01          | 60                   |
| **101**                   | 2026-01-01          | 50                   | **101**                   | 2026-07-02          | 65                   |
| **101**                   | 2026-01-02          | 55                   | **101**                   | 2026-07-01          | 60                   |
| **101**                   | 2026-01-02          | 55                   | **101**                   |                     |                      |

The solution is to drag calendar(2) into the Tableau data source and, using Tableau's "New Row Join" tool, drag calendar(3) directly below calendar(2) until the two .csv files merge. Then, access this new set and perform an inner join using the listing ID to retrieve all property listings that have a date recorded in the calendar.

## European configuration in Tableau
### Currency
Another thing to keep in mind: This project uses numeric fields from a dataset with American prices. There are some differences in the nomenclature compared to the European monetary system, mainly the differences between ',' and '.' and '$' and '€'.

Tableau automatically configures itself to process data based on your computer's location, and the parser doesn't always transform the data correctly. For this project, we'll use the 'Price' fields from both `listings.csv` and `calendar(2).csv and calendar(3).csv`, and when parsing, for example, **$85.00** to euros, it seems that Tableau transforms it to **€8,500**. Since we don't want to alter the values ​​in Excel, we'll do the following:
- Click on the 'Price' columns in ``listings.csv`, calendar(2).csv, and calendar(3).csv`

then press Ctrl+H and replace '$' with '' and '.00' with ''
- Change the data type to numeric
- Save everything in an Excel workbook to transfer it to Tableau (now the value of $85.00 would be 85)
### Location
Tableau permite ubicar códigos postales, pero si el sistema operativo tiene configuración en Europa/España/etc, puede que los ubique incorrectamente y/o que algunos o todos presenten ambiguedades. En ese caso, tendremos que modificar la localidad de los códigos postales al 'editar ubicación' y eligiendo el país como el país en el que queremos trabajar, para este proyecto el país será Estados Unidos.
# Procedure
The project, like other visualization editors, aims to represent a dataset to answer a series of questions that can be inferred from a large volume of data.

==The first question would be: **What is the average Airbnb price in each zip code/region of Seattle?**== To answer this question, we simply create a bar chart and set each column to represent the zip code and each row to represent the average price. Tableau's function with respect to the dataset is to sum ALL the prices within that zip code and divide by the number of rentals in that zip code to obtain the average.

Additionally, for this question, we can create another chart with a geographic map style and add the zip code to the columns, changing the data representation to 'Map'. Then, we add the zip code to the color scale to differentiate states, and as labels, we use the zip code and the average price.

The answer to this question is South of Downtown (SoDo with zip code 98134), likely due to a number of factors related to land scarcity, the electronics boom, strategic proximity, etc.

Note that if the zip codes are not displayed correctly on the map and appear as unknown values, it is advisable to edit the location and change the Country/Region from Spain to the United States.

==The second question would be: **During what time of year does the industry tend to move the most money?**== For this, we use a column for the date PER WEEK (which will be displayed as the first day of the week to count weeks) and the sum of the price for each row.

The result of this question shows two high peaks around the end of June and on December 25th, as a result of activity related to holidays and Christmas. On the other hand, there is a substantial drop around April 4th.

==The third question we'll answer is: **What is the most requested number of rooms per rental?**== 
To do this, we simply enter the number of rooms in each row (we want a horizontal chart) and in the data marker, we enter the average number of identifiers for each room, based on the number of rooms. Tableau then iterates through ALL the rental transactions for each number of rooms and sums all the identifiers.

The result by far is one-bedroom apartments, most likely due to short-term stays.

==The final question would be: **What is the most common number of bedrooms per rental unit?**==
To answer this question, we repeat the previous process, but to present it graphically, we use the number of bedrooms as columns and the average price of bedrooms for each number of bedrooms as rows and data points.

As with the previous question, 6-bedroom apartments are by far the most common. Furthermore, prices are very proportional to the number of bedrooms; there is no complex pattern.

Keep in mind that both this question and the previous one filter out extreme cases such as 7-bedroom apartments, which only have one record in the entire dataset, and, if they exist, apartments with 0 bedrooms or null values.