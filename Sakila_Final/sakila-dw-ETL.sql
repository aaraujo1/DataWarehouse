-- Include incremental loads for any tables that will allow it.
-- Create an ETL control procedure that handles the dates for incremental loads,
-- kicks off all the procedures in the proper order,
-- and correctly handles any errors that may occur.

-- DimCustomer
-- only insert the row for SK 0 if it doesn't exist
if (not exists(select *
               from DimCustomer
               where CustomerKey = 0))
    begin
        set identity_insert DimCustomer On
        insert into DimCustomer (CustomerKey,
                                 CustomerID,
                                 CustomerFirstName,
                                 CustomerLastName,
                                 CustomerEmail,
                                 CustomerAddressLine1,
                                 CustomerCity,
                                 CustomerCountry,
                                 CustomerIsActive,
                                 CustomerCreateDate,
                                 StartDate)
        Values (0,
                0,
                'Unknown Customer',
                'Unknown Customer',
                'Unknown Customer',
                'Unknown Customer',
                'Unknown Customer',
                'Unknown Customer',
                '0',
                getdate(),
                '2017-1-1')
        set identity_insert DimCustomer off
    end;


-- DimDate

-- populate DimDate beginning of time and end of time
if (not exists(select *
               from DimDate
               where DateKey = 19000101))
    begin
        declare @d datetime = '1/1/1900'
-- this is our "beginning of time"
        insert into DimDate
        select cast(convert(char(10), @d, 112) as int), -- key
               @d,                                      -- date
               datepart(d, @d),                         -- day of month
               datepart(m, @d),                         -- month number
               datename(m, @d),                         -- month name
               datepart(yy, @d),                        -- year
               datename(dw, @d),                        -- day of the week name
               datepart(dw, @d),                        -- day of the week number
               convert(bit,
                       case
                           when datepart(dw, @d) in (1, 7)
                               then 1
                           else 0
                           end
                   )
        -- if saturday or sunday, then is weekend
    end

if (not exists(select *
               from DimDate
               where DateKey = 99990101))
    begin
        declare @d datetime = '1/1/9999'
-- this is our "end of time"
        insert into DimDate
        select cast(convert(char(10), @d, 112) as int), -- key
               @d,                                      -- date
               datepart(d, @d),                         -- day of month
               datepart(m, @d),                         -- month number
               datename(m, @d),                         -- month name
               datepart(yy, @d),                        -- year
               datename(dw, @d),                        -- day of the week name
               datepart(dw, @d),                        -- day of the week number
               convert(bit,
                       case
                           when datepart(dw, @d) in (1, 7)
                               then 1
                           else 0
                           end
                   )
        -- if saturday or sunday, then is weekend
    end;
go



-- find earliest date
select min(rental_date), -- 2017-05-24
       min(return_date), -- 2017-05-25
       min(last_update)  -- 2018-02-15
from Sakila_AGA.dbo.rental;


-- start date will be 2017-1-1
-- end date will be getdate()
-- NOTE: unsure if I should have start date and end date to greater numbers

-- populate DimDate
declare @d datetime = '1/1/2017'
-- could be '1/1/1900'
-- keeping it high for disk space
-- this is our "date zero"
while (not (@d > '1/1/2030'))
    -- could be '1/1/9999'
    -- keeping it low for disk space
    begin
        insert into DimDate
        select cast(convert(char(10), @d, 112) as int), -- key
               @d,                                      -- date
               datepart(d, @d),                         -- day of month
               datepart(m, @d),                         -- month number
               datename(m, @d),                         -- month name
               datepart(yy, @d),                        -- year
               datename(dw, @d),                        -- day of the week name
               datepart(dw, @d),                        -- day of the week number
               convert(bit,
                       case
                           when datepart(dw, @d) in (1, 7)
                               then 1
                           else 0
                           end
                   )
        -- if saturday or sunday, then is weekend

        -- change value of @d
        set @d = dateadd(day, 1, @d)
    end

select *
from DimDate;


/*********************************
* Procedure DimRentalCountry_upsert
*
* Author: AAraujo
* Created: 03/02/2020
*
* This procedure populates the DimRentalCountry table.
*
*
* ***********************************/
create procedure DimRentalCountry_upsert
as
begin
    merge into DimRentalCountry as tgt
    using Sakila_AGA.dbo.country as src
    on tgt.CountryID = src.country_id
    when matched then
        update
        set CountryName = src.country
    when not matched by target then
        insert (CountryID,
                CountryName)
        values (src.country_id,
                src.country)
        ;
end
    ;

go

exec DimRentalCountry_upsert


/*********************************
* Procedure DimRentalCity_upsert
*
* Author: AAraujo
* Created: 03/02/2020
*
* This procedure populates the DimRentalCity table.
*
*
* ***********************************/
create procedure DimRentalCity_upsert
as
begin
    merge into DimRentalCity as tgt
    using Sakila_AGA.dbo.city as src
    on tgt.CityID = src.city_id
    when matched then
        update
        set CityName = src.city
    when not matched by target then
        insert (CityID,
                CityName)
        values (src.city_id,
                src.city)
        ;
end
    ;
go

exec DimRentalCity_upsert

/*********************************
* Procedure DimFilmCategory_upsert
*
* Author: AAraujo
* Created: 03/02/2020
*
* This procedure populates the DimFilmCategory table.
*
*
* ***********************************/
create procedure DimFilmCategory_upsert
as
begin
    merge into DimFilmCategory as tgt
    using Sakila_AGA.dbo.category as src
    on tgt.CategoryID = src.category_id
    when matched then
        update
        set CategoryName = src.name
    when not matched by target then
        insert (CategoryID,
                CategoryName)
        values (src.category_id,
                src.name)
        ;
end
    ;
go

exec DimFilmCategory_upsert

/*********************************
* Procedure DimFilmLanguage_upsert
*
* Author: AAraujo
* Created: 03/02/2020
*
* This procedure populates the DimFilmLanguage table.
*
*
* ***********************************/
create procedure DimFilmLanguage_upsert
as
begin
    merge into DimFilmLanguage as tgt
    using Sakila_AGA.dbo.language as src
    on tgt.LanguageID = src.language_id
    when matched then
        update
        set LanguageName = src.name
    when not matched by target then
        insert (LanguageID,
                LanguageName)
        values (src.language_id,
                src.name)
        ;
end
    ;
go

exec DimFilmLanguage_upsert

/*********************************
* Procedure DimFilm_upsert
*
* Author: AAraujo
* Created: 03/02/2020
*
* This procedure populates the DimFilm table.
*
*
* ***********************************/
create procedure DimFilm_upsert
as
begin
    merge into DimFilm as tgt
    using Sakila_AGA.dbo.film as src
    on tgt.FilmID = src.film_id
    when matched then
        update
        set Title           = src.title,
            Description     = src.description,
            ReleaseYear     = src.release_year,
            RentalDuration  = src.rental_duration,
            RentalRate      = src.rental_rate,
            Length          = src.length,
            ReplacementCost = src.replacement_cost,
            Rating          = src.rating,
            SpecialFeatures = src.special_features
    when not matched by target then
        insert (FilmID,
                Title,
                Description,
                ReleaseYear,
                RentalDuration,
                RentalRate,
                Length,
                ReplacementCost,
                Rating,
                SpecialFeatures)
        values (src.film_id,
                src.title,
                src.description,
                src.release_year,
                src.rental_duration,
                src.rental_rate,
                src.length,
                src.replacement_cost,
                src.rating,
                src.special_features)
        ;
end
    ;
go

exec DimFilm_upsert

/*********************************
* Procedure DimStore_upsert
*
* Author: AAraujo
* Created: 03/02/2020
*
* This procedure populates the DimStore table.
*
*
* ***********************************/
create procedure DimStore_upsert
as
begin
    merge into DimStore as tgt
    using (
        select sto.store_id,
               sta.first_name,
               sta.last_name,
               sta.email,
               a.address,
               a.address2,
               a.district,
               ci.city,
               co.country,
               a.postal_code,
               a.phone
        from Sakila_AGA.dbo.store sto
                 join Sakila_AGA.dbo.staff sta on sto.manager_staff_id = sta.staff_id
                 join Sakila_AGA.dbo.address a on sto.address_id = a.address_id
                 join Sakila_AGA.dbo.city ci on a.city_id = ci.city_id
                 join Sakila_AGA.dbo.country co on ci.country_id = co.country_id
    ) as src
    on tgt.StoreID = src.store_id
    when matched then
        update
        set StoreID               = store_id,
            StoreManagerFirstName = first_name,
            StoreManagerLastName  = last_name,
            StoreManagerEmail     = email,
            StoreAddressLine1     = address,
            StoreAddressLine2     = address2,
            StoreDistrict         = district,
            StoreCity             = city,
            StoreCountry          = country,
            StorePostalCode       = postal_code,
            StorePhone            = phone
    when not matched by target then
        insert (StoreID,
                StoreManagerFirstName,
                StoreManagerLastName,
                StoreManagerEmail,
                StoreAddressLine1,
                StoreAddressLine2,
                StoreDistrict,
                StoreCity,
                StoreCountry,
                StorePostalCode,
                StorePhone)
        values (src.store_id,
                src.first_name,
                src.last_name,
                src.email,
                src.address,
                src.address2,
                src.district,
                src.city,
                src.country,
                src.postal_code,
                src.phone)
        ;
end
    ;
go

exec DimStore_upsert

/*********************************
* Procedure DimCustomer_upsert
*
* Author: AAraujo
* Created: 03/04/2020
*
* This procedure populates the DimCustomer table.
* It handles Type 2 Slowly Changing dimensions
* for a customer’s name & address
*
* ***********************************/
-- run by date ranges
-- changes to start
create or alter procedure DimCustomer_upsert
as
begin


    begin try


        begin tran
            -- create temp table
            create table #tempCustomer
            (
                [Action]               varchar(20),
                [CustomerID]           smallint,
                [CustomerFirstName]    varchar(45),
                [CustomerLastName]     varchar(45),
                [CustomerEmail]        varchar(50),
                [CustomerAddressLine1] varchar(50),
                [CustomerAddressLine2] varchar(50),
                [CustomerDistrict]     varchar(20),
                [CustomerCity]         varchar(50),
                [CustomerCountry]      varchar(50),
                [CustomerPostalCode]   varchar(10),
                [CustomerPhone]        varchar(20),
                [CustomerIsActive]     bit,
                [CustomerCreateDate]   datetime,
                [StartDate]            datetime,
                [EndDate]              datetime,
                [CurrentRowIndicator]  bit,
                [Inserted]             int,
                [Updated]              int
            )

            merge into dbo.DimCustomer as tgt
            using (
                select c.customer_id,
                       c.first_name,
                       c.last_name,
                       c.email,
                       a.address,
                       a.address2,
                       a.district,
                       ci.city,
                       co.country,
                       a.postal_code,
                       a.phone,
                       c.active,
                       c.create_date,
                       c.last_update
                from Sakila_AGA.dbo.customer c
                         join Sakila_AGA.dbo.address a on c.address_id = a.address_id
                         join Sakila_AGA.dbo.city ci on a.city_id = ci.city_id
                         join Sakila_AGA.dbo.country co on ci.country_id = co.country_id
            ) as src
            on tgt.CustomerID = src.customer_id
                and tgt.CurrentRowIndicator = 1 -- checks only most current record
            when matched and not (
                -- checks for a change in customer’s name & address
                    tgt.CustomerFirstName = src.first_name
                    and tgt.CustomerLastName = src.last_name
                    and tgt.CustomerAddressLine1 = src.address
                    and tgt.CustomerAddressLine2 = src.address2
                    and tgt.CustomerCity = src.city
                    and tgt.CustomerCountry = src.country
                    and tgt.CustomerPostalCode = src.postal_code
                )
                then
                -- if there is a change, make EndDate to today and change CurrentRowIndicator to 0/no
                update
                set EndDate             = getdate(),
                    CurrentRowIndicator = 0
            when not matched by target then
                -- insert new data
                insert ([CustomerID],
                        [CustomerFirstName],
                        [CustomerLastName],
                        [CustomerEmail],
                        [CustomerAddressLine1],
                        [CustomerAddressLine2],
                        [CustomerDistrict],
                        [CustomerCity],
                        [CustomerCountry],
                        [CustomerPostalCode],
                        [CustomerPhone],
                        [CustomerIsActive],
                        [CustomerCreateDate],
                        [StartDate],
                        [EndDate],
                        [CurrentRowIndicator])
                values (src.customer_id,
                        src.first_name,
                        src.last_name,
                        src.email,
                        src.address,
                        src.address2,
                        src.district,
                        src.city,
                        src.country,
                        src.postal_code,
                        src.phone,
                        src.active,
                        src.create_date,
                        src.create_date,
                        '1/1/9999 23:59:59.996',
                        1)
                -- output to temp table
                output $action as Action,
                    src.customer_id,
                    src.first_name,
                    src.last_name,
                    src.email,
                    src.address,
                    src.address2,
                    src.district,
                    src.city,
                    src.country,
                    src.postal_code,
                    src.phone,
                    src.active,
                    src.create_date,
                    inserted.EndDate as StartDate,
                    '1/1/9999 23:59:59.996' as EndDate,
                    1 as CurrentRowIndicator,
                    inserted.CustomerKey as Inserted,
                    deleted.CustomerKey as Updated
                    into #tempCustomer
                ;


            insert into DimCustomer([CustomerID],
                                    [CustomerFirstName],
                                    [CustomerLastName],
                                    [CustomerEmail],
                                    [CustomerAddressLine1],
                                    [CustomerAddressLine2],
                                    [CustomerDistrict],
                                    [CustomerCity],
                                    [CustomerCountry],
                                    [CustomerPostalCode],
                                    [CustomerPhone],
                                    [CustomerIsActive],
                                    [CustomerCreateDate],
                                    [StartDate],
                                    [EndDate],
                                    [CurrentRowIndicator])
            select tc.CustomerID,
                   tc.CustomerFirstName,
                   tc.CustomerLastName,
                   tc.CustomerEmail,
                   tc.CustomerAddressLine1,
                   tc.CustomerAddressLine2,
                   tc.CustomerDistrict,
                   tc.CustomerCity,
                   tc.CustomerCountry,
                   tc.CustomerPostalCode,
                   tc.CustomerPhone,
                   tc.CustomerIsActive,
                   tc.CustomerCreateDate,
                   getdate(),
                   '1/1/9999 23:59:59.996',
                   1
            from #tempCustomer tc
            where Action = 'Update'
        commit;
    end try
    begin catch
        rollback ;
    end catch
end;

go

exec DimCustomer_upsert


/*********************************
* Procedure FactRental_upsert
*
* Author: AAraujo
* Created: 03/04/2020
*
* This procedure populates the FactRental table.
*
* Parameters
* ----------
* @SinceDate datetime  - for incremental loads
*
* ----------
* Change
* ----------
* 03/09/2020 AAraujo  - added parameter for incremental loads
*
* ***********************************/
create or alter procedure FactRental_upsert(@SinceDate datetime)
as
begin
    merge into FactRental as tgt
    using (
        select                 r.rental_id,
                               r.rental_date,
                               r.return_date,
                               datediff(day, r.return_date, r.rental_date) as [rental_duration],
                               p.amount,
                               p.payment_date,
            FilmKey          = df.FilmKey,
            FilmCategoryKey  = dfc.FilmCategoryKey,
            FilmLanguageKey  = dfl.FilmLanguageKey,
            RentalCityKey    = drci.RentalCityKey,
            RentalCountryKey = drco.RentalCountryKey,
                               isnull(dcu.CustomerKey, 0)                  as CustomerKey, -- if unknown customer, key 0
            StoreKey         = ds.StoreKey,
            RentalDateKey    = ddrent.DateKey,
            ReturnDateKey    = ddreturn.DateKey,
            PaymentDateKey   = ddpay.DateKey
        from Sakila_AGA.dbo.rental r
                 join Sakila_AGA.dbo.payment p on r.rental_id = p.rental_id
                 join Sakila_AGA.dbo.inventory i on r.inventory_id = i.inventory_id
                 join Sakila_AGA.dbo.film f on i.film_id = f.film_id
                 join Sakila_AGA.dbo.film_category fc on f.film_id = fc.film_id
                 join Sakila_AGA.dbo.category c on fc.category_id = c.category_id
                 join Sakila_AGA.dbo.language l on f.language_id = l.language_id
                 join Sakila_AGA.dbo.store s on i.store_id = s.store_id
                 join Sakila_AGA.dbo.address a on s.address_id = a.address_id
                 join Sakila_AGA.dbo.city ci on a.city_id = ci.city_id
                 join Sakila_AGA.dbo.country co on ci.country_id = co.country_id
                 join Sakila_AGA.dbo.customer cu on r.customer_id = cu.customer_id
                 join DimFilm df on f.film_id = DF.FilmID
                 join DimFilmCategory dfc on c.category_id = dfc.CategoryID
                 join DimFilmLanguage dfl on l.language_id = dfl.LanguageID
                 join DimRentalCity drci on ci.city_id = drci.CityID
                 join DimRentalCountry drco on co.country_id = drco.CountryID
                 left join DimCustomer dcu on cu.customer_id = dcu.CustomerID
            --and r.rental_date between dcu.StartDate and dcu.EndDate
                 left join DimStore ds on s.store_id = ds.StoreID
                 left join DimDate ddrent on cast(r.rental_date as date) = ddrent.Date
                 left join DimDate ddreturn on cast(r.return_date as date) = ddreturn.Date
                 left join DimDate ddpay on cast(p.payment_date as date) = ddpay.Date
             -- checks both rental and return date changes
        where r.rental_date >= @SinceDate
           or r.return_date >= @SinceDate
    ) as src
    on tgt.RentalID = src.rental_id
    when matched then
        update
        set tgt.RentalDateKey  = src.RentalDateKey,
            tgt.RentalDate     = src.rental_date,
            tgt.ReturnDateKey  = src.ReturnDateKey,
            tgt.ReturnDate     = src.return_date,
            tgt.RentalDuration = src.rental_duration,
            tgt.Amount         = src.amount,
            tgt.PaymentDateKey = src.PaymentDateKey,
            tgt.PaymentDate    = src.payment_date
    when not matched by target then
        insert (RentalID,
                RentalDate,
                ReturnDate,
                RentalDuration,
                Amount,
                PaymentDate,
                FilmKey,
                FilmCategoryKey,
                FilmLanguageKey,
                RentalCityKey,
                RentalCountryKey,
                CustomerKey,
                StoreKey,
                RentalDateKey,
                ReturnDateKey,
                PaymentDateKey)
        values (src.rental_id,
                src.rental_date,
                src.return_date,
                src.rental_duration,
                src.Amount,
                src.payment_date,
                src.FilmKey,
                src.FilmCategoryKey,
                src.FilmLanguageKey,
                src.RentalCityKey,
                src.RentalCountryKey,
                src.CustomerKey,
                src.StoreKey,
                src.RentalDateKey,
                src.ReturnDateKey,
                src.PaymentDateKey)
        ;

end
    ;
go

exec FactRental_Upsert

dbcc checkident ('FactRental', reseed, 0)

declare @Date date = '1999-1-1'
exec FactRental_Upsert @date

-------------------------------
-- Control procedure
-------------------------------
/*********************************
* Procedure ETL_Control
*
* Author: AAraujo
* Created: 03/09/2020
*
* This procedure populates the Sakila Data Warehouse.
*
* Parameters
* ----------
* @SinceDate datetime  - for incremental loads
*
* ----------
* Change
* ----------
* 03/09/2020 AAraujo  - added parameter for incremental loads
*
* ***********************************/
create or alter procedure ETL_Control(@SinceDate datetime)
as
begin

    --declare @Date date = getdate() -- this would typically be selected from a date control table

    begin try
        begin tran
            exec DimRentalCountry_upsert
            exec DimRentalCity_upsert
            exec DimFilm_upsert
            exec DimFilmCategory_upsert
            exec DimFilmLanguage_upsert
            exec DimStore_upsert
            exec DimCustomer_upsert
            exec FactRental_Upsert @SinceDate -- this procedure requires a date

        commit;
    end try
    begin catch
        rollback;
    end catch
end;
go


exec ETL_Control @SinceDate = '2020-4-17'