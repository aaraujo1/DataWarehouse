/*---- create db ----*/
/*use master;
go

create database SakilaDW_AGA;
go*/

/*---- create tables ----*/

/*
 * note: nulls are allowed where the source tables has nulls
 */

-- dimension table for rental country
-- slowly changing dimension type 1 - overwrite
create table [DimRentalCountry]
(
    [RentalCountryKey] smallint identity (1,1),
    [CountryID]        smallint    not null,
    [CountryName]      varchar(50) not null,
    constraint pk_DimRentalCountry primary key ([RentalCountryKey])
);
go

-- dimension table for rental city
-- slowly changing dimension type 1 - overwrite
create table [DimRentalCity]
(
    [RentalCityKey] smallint identity (1,1),
    [CityID]        smallint    not null,
    [CityName]      varchar(50) not null,
    constraint pk_DimRentalCity primary key ([RentalCityKey])
);
go

-- dimension table for customer
-- could be slowly changing dimension type 2
-- to keep a history of all name/address combination,
-- which is most of the information on the table
-- could by SCD type 4 to keep only name/address information
create table [DimCustomer]
(
    [CustomerKey]          smallint identity (1,1),
    [CustomerID]           smallint    not null,
    [CustomerFirstName]    varchar(45) not null,
    [CustomerLastName]     varchar(45) not null,
    [CustomerEmail]        varchar(50) not null,
    [CustomerAddressLine1] varchar(50) not null,
    [CustomerAddressLine2] varchar(50),                               -- can be null
    [CustomerDistrict]     varchar(20),                               -- can be null
    [CustomerCity]         varchar(50) not null,
    [CustomerCountry]      varchar(50) not null,
    [CustomerPostalCode]   varchar(10),                               -- can be null
    [CustomerPhone]        varchar(20),                               -- can be null
    [CustomerIsActive]     bit         not null,
    [CustomerCreateDate]   datetime    not null,
    [StartDate]            datetime    not null,                      -- will come from source table (last_update)
    [EndDate]              datetime    not null default '12/31/9999', -- default to future time
    [CurrentRowIndicator]  bit         not null default 1,            -- set to is default
    constraint pk_DimCustomer primary key ([CustomerKey])
);
go

-- dimension table for stores
-- slowly changing dimension type 1 - overwrite
-- could be slowly changing dimension type 3 for change managerial changes
create table [DimStore]
(
    [StoreKey]              tinyint identity (1,1),
    [StoreID]               tinyint     not null,
    [StoreManagerFirstName] varchar(45) not null,
    [StoreManagerLastName]  varchar(45) not null,
    [StoreManagerEmail]     varchar(50) not null,
    [StoreAddressLine1]     varchar(50) not null,
    [StoreAddressLine2]     varchar(50) ,
    [StoreDistrict]         varchar(20) not null,
    [StoreCity]             varchar(50) not null,
    [StoreCountry]          varchar(50) not null,
    [StorePostalCode]       varchar(10) not null,
    [StorePhone]            varchar(20) not null,
    constraint pk_DimStore primary key ([StoreKey])
);
go

-- dimension table for film
-- slowly changing dimension type 1 - overwrite
-- could be slowly changing dimension type 3
-- for RentalDuration, RentalRate, and ReplacementCost
create table [DimFilm]
(
    [FilmKey]         smallint identity (1,1),
    [FilmID]          smallint      not null,
    [Title]           varchar(255)  not null,
    [Description]     varchar(max)  not null,
    [ReleaseYear]     numeric(4)    not null,
    [RentalDuration]  tinyint       not null,
    [RentalRate]      decimal(4, 2) not null,
    [Length]          smallint      not null,
    [ReplacementCost] decimal(5, 2) not null,
    [Rating]          varchar(5)    not null,
    [SpecialFeatures] varchar(100), -- can be null
    constraint pk_DimFilm primary key ([FilmKey])
);
go

-- dimension table for film category
create table [DimFilmCategory]
(
    [FilmCategoryKey] tinyint identity (1,1),
    [CategoryID]      tinyint     not null,
    [CategoryName]    varchar(25) not null,
    constraint pk_DimFilmCategory primary key ([FilmCategoryKey])
);
go

-- dimension table for film language
create table [DimFilmLanguage]
(
    [FilmLanguageKey] tinyint identity (1,1),
    [LanguageID]      tinyint  not null,
    [LanguageName]    char(20) not null,
    constraint pk_DimFilmLanguage primary key ([FilmLanguageKey])
);
go

-- dimension table for dates
-- slowly changing dimension type 0
create table [DimDate]
(
    [DateKey]         int         not null,
    [Date]            date        not null,
    [DayOfMonth]      tinyint     not null,
    [MonthNumber]     tinyint     not null,
    [MonthName]       varchar(10) not null,
    [Year]            smallint    not null,
    [DayOfWeekName]   varchar(10) not null,
    [DayOfWeekNumber] tinyint     not null,
    [IsWeekend]       bit         not null,
    constraint pk_DimDate primary key ([DateKey])
);
go

-- fact table for rentals
create table [FactRental]
(
    [RentalKey]        bigint identity (1,1),
    [RentalID]         bigint   not null, -- 5 payments have null for rental id. Check if ok
    [RentalDate]       datetime not null,
    [ReturnDate]       datetime,          -- can be null
    [RentalDuration]   int, -- can be null
    [Amount]           decimal(5,2)  not null,
    [PaymentDate]      datetime not null,
    [FilmKey]          smallint not null,
    [FilmCategoryKey]  tinyint  not null,
    [FilmLanguageKey]  tinyint  not null,
    [RentalCityKey]    smallint not null,
    [RentalCountryKey] smallint not null,
    [CustomerKey]      smallint not null,
    [StoreKey]         tinyint  not null,
    [RentalDateKey]    int      not null,
    [ReturnDateKey]    int, -- can be null
    [PaymentDateKey]   int      not null,
    constraint pk_FactRental primary key ([RentalKey]),
    constraint fk_FactRental_FilmKey foreign key ([FilmKey]) references DimFilm (FilmKey),
    constraint fk_FactRental_FilmCategoryKey foreign key ([FilmCategoryKey]) references DimFilmCategory (FilmCategoryKey),
    constraint fk_FactRental_FilmLanguageKey foreign key (FilmLanguageKey) references DimFilmLanguage (FilmLanguageKey),
    constraint fk_FactRental_RentalCityKey foreign key ([RentalCityKey]) references DimRentalCity (RentalCityKey),
    constraint fk_FactRental_RentalCountryKey foreign key ([RentalCountryKey]) references DimRentalCountry (RentalCountryKey),
    constraint fk_FactRental_CustomerKey foreign key ([CustomerKey]) references DimCustomer (CustomerKey),
    constraint fk_FactRental_StoreKey foreign key ([StoreKey]) references DimStore (StoreKey),
    constraint fk_FactRental_RentalDateKey foreign key ([RentalDateKey]) references DimDate (DateKey),
    constraint fk_FactRental_ReturnDateKey foreign key ([ReturnDateKey]) references DimDate (DateKey),
    constraint fk_FactRental_PaymentDateKey foreign key ([PaymentDateKey]) references DimDate (DateKey)
);


