Create table RoomTypes
(
	RoomTypeID varchar (10) not null primary key Check (RoomTypeID like 'RT-[0-9][0-9][0-9][0-9][0-9]'),
	RoomTypeName varchar (50) not null,
	Price Decimal (10,2) Check (Price > 0),
	NumberOfBeds integer check (NumberOfBeds >= 1),
	RoomWidth Decimal(3,2) check (RoomWidth >= 1),
	RoomLength Decimal (3,2) check (RoomLength >= 1),
	Description Varchar (200)
);

Create table Rooms
(
	RoomID varchar (10) Check (RoomID like 'R-[0-9][0-9][0-9][0-9][0-9]') primary key,
	RoomTypeID varchar (10), 
	foreign key (RoomTypeID) references RoomTypes (RoomTypeID) on delete no action on update cascade,
	Occupied_Status bit Default 0 not null
);

Create table Customers
(
	CustomerID Varchar (10) Check (CustomerID like 'C-[0-9][0-9][0-9][0-9][0-9]') primary key,
	FirstName Varchar (50) not null,
	LastName Varchar (50) not null,
	Phone Varchar (30) Check (Phone not like '%[^0-9]%'),
	Email Varchar (200) Check (Email like '%_@__%.__%') unique,
	Gender Char (1) Check (Gender in ('M', 'F', 'O')),
	Age Integer Check (Age >= 18),
	NRC Varchar(30) unique
);

Create table Staff
(
	StaffID Varchar (10) Check (StaffID like 'S-[0-9][0-9][0-9][0-9][0-9]') primary key,
	StaffName Varchar (80) not null,
	StaffPhone Varchar (30) Check (StaffPhone not like '%[^0-9]%'),
	StaffEmail Varchar (200) Check (StaffEmail like '%_@__%.__%') unique,
	StaffAddress Varchar (1000) not null,
	StaffNRC Varchar (30) unique
);

Create table Reservations 
(
	ReservationID Varchar(10) Check (ReservationID like 'Rer-[0-9][0-9][0-9][0-9][0-9]') primary key,
	ReservationStartDate Date  Not null,
	ReservationEndDate AS DateAdd (day, 3, ReservationStartDate),
	CustomerID Varchar (10) foreign key references Customers (CustomerID) on delete no action on update cascade,
	StaffID Varchar (10) foreign key references Staff (StaffID) on delete no action on update cascade
);

Create table Room_Reservation
(
	ReservationID Varchar(10) foreign key references Reservations(ReservationID) on delete no action on update cascade,
	RoomID Varchar (10) foreign key references Rooms(RoomID) on delete no action on update cascade,
	Cancelled bit not null Default 0,
	Primary Key (ReservationID, RoomID)
);

Create table Occupations
(
	OccupationID Varchar (10) Check (OccupationID like 'O-[0-9][0-9][0-9][0-9][0-9]') primary key,
	ReservationID Varchar (10) foreign key references Room_Reservations(ReservationID) on delete no action on update cascade,
	RoomID Varchar (10) foreign key references Rooms (RoomID) on delete no action on update cascade,
	CheckInDateTime DateTime, 
	CheckOutDateTime DateTime 
); 

CREATE TRIGGER trg_CheckDateTimeRange
ON Occupations
For INSERT, UPDATE
AS
Begin
    IF EXISTS (
        SELECT 1
        FROM inserted i
        INNER JOIN Reservations r ON i.ReservationID = r.ReservationID
        WHERE i.CheckInDateTime < r.ReservationStartDate
           OR i.CheckInDateTime > r.ReservationEndDate
           OR i.CheckOutDateTime < i.CheckInDateTime
    )
    BEGIN
        Print('Check-in and check-out dates are invalid for the reservation.');
        ROLLBACK TRANSACTION;
    END;
END;

Create table Occupants
(
	OccupantID Varchar (10) Check (OccupantID like 'OCU-[0-9][0-9][0-9][0-9][0-9]') primary key,
	OccupantName Varchar (80) Not null,
	Email Varchar (200) Check (Email like '%_@__%.__%'),
	Phone Varchar (30) Check (Phone not like '%[^0-9]%'),
	Gender Char (1) Check (Gender in ('M', 'F', 'O')),
	Age int Check (Age > 0)
);

Create table Occupation_List
(
	OccupationID varchar (10) foreign key references Occupations (OccupationID) on delete no action on update cascade,
	OccupantID varchar (10) foreign key references Occupants (OccupantID) on delete no action on update cascade,
	Primary Key (OccupationID, OccupantID)
);

Create Table Amenities
(
	AmenityID varchar(10) check(AmenityID like 'A-[0-9][0-9][0-9][0-9][0-9]') primary key not null,
	AmenityName varchar(50) not null,
	Description varchar(200),
);

Create table Amenity_RoomType
(
	AmenityID Varchar (10) foreign key references Amenities (AmenityID) on delete cascade on update no action,
	RoomTypeID Varchar (10) foreign key references RoomTypes (RoomTypeID) on delete cascade on update no action,
	Primary Key (AmenityID, RoomTypeID)
);

Create table PaymentTypes 
(
	PaymentTypeID Varchar (10) primary key check (PaymentTypeID like 'PT-[0-9][0-9][0-9][0-9][0-9]'),
	PaymentTypeName Varchar (50) not null,
);

Create table Payments
(
	ReservationID Varchar (10) foreign key references Reservations (ReservationID) on delete no action on update cascade,
	PaymentAmount Decimal (10,2) not null Check (PaymentAmount > 0.00),
	PaymentTypeID Varchar (10) foreign key references PaymentTypes (PaymentTypeID) on delete no action on update cascade,
);

Create trigger trg_PaymentAmount
On Payments
After Insert, Update
AS
Begin
	Update p
	Set p.PaymentAmount = (Select  SUM(rt.Price * (DATEDIFF(DAY, o.CheckInDateTime, o.CheckOutDateTime)))
From Occupations o
Inner Join Room_Reservation rr on rr.ReservationID = o.ReservationID
AND rr.RoomID = o.RoomID
Inner Join Rooms r on rr.RoomID = r.RoomID 
Inner Join Reservations rer on rer.ReservationID = rr.ReservationID
Inner Join RoomTypes rt on rt.RoomTypeID = r.RoomTypeID
Where o.ReservationID = i.ReservationID
Group by  o.ReservationID, o.CheckInDateTime, o.CheckOutDateTime)
	From Payments p
	Inner Join inserted i on p.ReservationID = i.ReservationID;
End;


Select * from Customers

Select * from RoomTypes

Select * from Rooms

Select * from Customers

Select * From Staff

Select * from Reservations

Select * from Occupations

Select * from Occupants

Select * from Occupation_List

Select * from Amenities

Select * from Amenity_RoomType

Select * from PaymentTypes

Select * from Payments

Insert Into RoomTypes (RoomTypeID, RoomTypeName, Price, NumberOfBeds, RoomWidth, RoomLength, Description)
Values	('RT-00001', 'Standard Room', 100.00, 2, 3.5, 5.0, 'Comfortable standard room.'),
    ('RT-00002', 'Deluxe Room', 150.00, 2, 4.0, 5.5, 'Luxurious deluxe room with additional amenities.'),
    ('RT-00003', 'Suite', 250.00, 4, 5.0, 6.0, 'Spacious suite with separate living area and kitchenette.'),
    ('RT-00004', 'Executive Room', 180.00, 2, 4.0, 5.0, 'Executive room with work desk and lounge access.'),
    ('RT-00005', 'Family Room', 200.00, 4, 4.5, 6.5, 'Family-friendly room with connecting rooms and games.'),
    ('RT-00006', 'Poolside Room', 120.00, 2, 4.0, 5.0, 'Room with poolside access and private patio.'),
    ('RT-00007', 'Pet-Friendly', 110.00, 2, 3.5, 5.0, 'Pet-friendly room with amenities for pets.'),
    ('RT-00008', 'Honeymoon Suite', 300.00, 2, 5.0, 6.0, 'Romantic honeymoon suite with Jacuzzi.'),
    ('RT-00009', 'Business Suite', 220.00, 2, 4.5, 6.0, 'Business suite with workstation and meeting room access.'),
    ('RT-00010', 'Ocean View Room', 180.00, 2, 4.0, 5.5, 'Room with ocean view and beach access.');



Insert Into Amenities (AmenityID, AmenityName, Description)
Values ('A-00001', 'Free Wi-Fi', 'Complimentary high-speed Wi-Fi access in the room.'),
    ('A-00002', 'En-suite bathroom', 'Private bathroom attached to the room for your convenience.'),
    ('A-00003', 'TV with cable/satellite channels', 'Enjoy a variety of TV channels and entertainment options.'),
    ('A-00004', 'Air conditioning/heating', 'Adjust room temperature for your comfort.'),
    ('A-00005', 'In-room safe', 'Secure storage for your valuables within the room.'),
    ('A-00006', 'Complimentary toiletries', 'Basic toiletries provided for your stay.'),
    ('A-00007', 'En-suite bathroom with upgraded toiletries', 'Private bathroom with premium toiletries.'),
    ('A-00008', 'Mini refrigerator', 'A compact refrigerator for storing snacks and beverages.'),
    ('A-00009', 'Coffee/tea maker', 'Prepare your favorite hot beverages in the room.'),
    ('A-00010', 'Work desk', 'A designated work area for your convenience.'),
    ('A-00011', 'Separate living area', 'Spacious living area separate from the bedroom.'),
    ('A-00012', 'Kitchenette or full kitchen', 'Kitchen facilities for preparing meals.'),
    ('A-00013', 'Complimentary breakfast', 'Enjoy a complimentary breakfast during your stay.'),
	('A-00014', 'Access to business lounge', 'Exclusive access to a business lounge with amenities.'),
    ('A-00015', 'Complimentary newspapers', 'Stay updated with complimentary newspapers.'),
    ('A-00016', 'Connecting/adjoining rooms', 'Rooms that can be connected for larger groups or families.'),
    ('A-00017', 'Kid-friendly amenities', 'Amenities designed with kids in mind.'),
    ('A-00018', 'Board games or game console', 'Entertainment options for family fun.'),
    ('A-00019', 'Private patio or balcony with pool view', 'Enjoy a private outdoor space with pool views.'),
    ('A-00020', 'Poolside access', 'Direct access to the pool area from your room.'),
    ('A-00021', 'Pool towels and robes', 'Complimentary towels and robes for pool use.'),
    ('A-00022', 'Pet amenities', 'Amenities for guests traveling with pets. Such as pet bed, bowls, treats'),
    ('A-00023', 'Direct outdoor access', 'Easy access to outdoor areas for pet walks.'),
    ('A-00024', 'Pet-friendly dining', 'Pet-friendly dining options on-site.'),
    ('A-00025', 'Romantic décor and ambiance', 'Specially decorated room for a romantic experience.'),
    ('A-00026', 'Jacuzzi or private hot tub', 'Relax in a Jacuzzi or private hot tub in your room.'),
    ('A-00027', 'Champagne and chocolates', 'Enjoy champagne and chocolates during your stay.'),
    ('A-00028', 'Workstation', 'A dedicated workstation with printing and scanning facilities.'),
    ('A-00029', 'Meeting room access', 'Access to meeting rooms for business purposes.'),
    ('A-00030', 'Complimentary evening cocktails', 'Enjoy complimentary cocktails in the evening.'),
    ('A-00031', 'Private balcony with ocean view', 'A private balcony with breathtaking ocean views.'),
    ('A-00032', 'Binoculars for whale watching', 'Binoculars for whale watching from your room.'),
    ('A-00033', 'Beach access and equipment', 'Access to the beach with complimentary equipment. Such as beach umbrella and chairs');

Insert into Amenity_RoomType(AmenityID, RoomTypeID)
Values ('A-00001', 'RT-00001'),
    ('A-00002', 'RT-00001'),
    ('A-00003', 'RT-00001'),
    ('A-00004', 'RT-00001'),
    ('A-00001', 'RT-00002'),
    ('A-00007', 'RT-00002'),
    ('A-00008', 'RT-00002'),
    ('A-00001', 'RT-00003'),
    ('A-00011', 'RT-00003'),
    ('A-00012', 'RT-00003'),
    ('A-00001', 'RT-00004'),
    ('A-00010', 'RT-00004'),
    ('A-00014', 'RT-00004'),
    ('A-00015', 'RT-00004'),
    ('A-00001', 'RT-00005'),
    ('A-00016', 'RT-00005'),
    ('A-00017', 'RT-00005'),
    ('A-00018', 'RT-00005'),
    ('A-00001', 'RT-00006'),
    ('A-00019', 'RT-00006'),
    ('A-00020', 'RT-00006'),
    ('A-00021', 'RT-00006'),
    ('A-00001', 'RT-00007'),
    ('A-00022', 'RT-00007'),
    ('A-00023', 'RT-00007'),
    ('A-00024', 'RT-00007'),
    ('A-00001', 'RT-00008'),
    ('A-00025', 'RT-00008'),
    ('A-00026', 'RT-00008'),
    ('A-00027', 'RT-00008'),
    ('A-00001', 'RT-00009'),
    ('A-00028', 'RT-00009'),
    ('A-00029', 'RT-00009'),
    ('A-00030', 'RT-00009'),
    ('A-00001', 'RT-00010'),
    ('A-00031', 'RT-00010'),
    ('A-00032', 'RT-00010'),
    ('A-00033', 'RT-00010');


Insert into Rooms (RoomID, RoomTypeID, Occupied_Status)
Values ('R-00001', 'RT-00001', 0),
	('R-00002', 'RT-00001', 1),
	('R-00003', 'RT-00001', 0),
	('R-00004', 'RT-00002', 1),
	('R-00005', 'RT-00002', 0),
	('R-00006', 'RT-00002', 1),
	('R-00007', 'RT-00003', 0),
	('R-00008', 'RT-00003', 1),
	('R-00009', 'RT-00003', 1),
	('R-00010', 'RT-00004', 1),
	('R-00011', 'RT-00004', 0),
	('R-00012', 'RT-00004', 1),
	('R-00013', 'RT-00005', 1),
	('R-00014', 'RT-00005', 0),
	('R-00015', 'RT-00005', 0),
	('R-00016', 'RT-00006', 0),
	('R-00017', 'RT-00006', 1),
	('R-00018', 'RT-00006', 0),
	('R-00019', 'RT-00007', 1),
	('R-00020', 'RT-00007', 1),
	('R-00021', 'RT-00007', 1),
	('R-00022', 'RT-00008', 1),
	('R-00023', 'RT-00008', 0),
	('R-00024', 'RT-00008', 1),
	('R-00025', 'RT-00009', 1),
	('R-00026', 'RT-00009', 0),
	('R-00027', 'RT-00009', 1),
	('R-00028', 'RT-00010', 1),
	('R-00029', 'RT-00010', 0),
	('R-00030', 'RT-00010', 1);


Insert into Customers (CustomerID, FirstName, LastName, Phone, Email, Gender, Age, NRC)
Values ('C-00001','John', 'Smith', '15551234567', 'johnsmith@kmd.edu.mm', 'M', 18, '6/OUKAMA(N)385421'),
	('C-00002','Emily', 'Lee', '442071234567', 'emily.lee@leeenterprises.com', 'F', 25, '3/OUKAMA(N)903176'),
	('C-00003','Robert', 'Brown', '33123456789', 'robert.brown@brownindustries.net', 'M', 54, '8/THKATA(N)642859'),
	('C-00004','Lisa', 'Johnson', '493012345678', 'lisa.johnson@johnsonconsulting.org', 'O', 45, '6/AHLANA(N)217504'),
	('C-00005','Michael', 'Taylor', '81312345678', 'michael.taylor@taylorglobal.biz', 'M', 63, '12/KAMATA(N)765432'),
	('C-00006','Sophia', 'Davis', '861012345678', 'sophia.davis@davisincorporated.co', 'O', 32, '12/YAMAKA(N)129875'),
	('C-00007','Sophia', 'Wilson', '912212345678', 'ethan.wilson@wilsonpartnership.info', 'F', 25, '12/OUKAMA(N)506734'),
	('C-00008','Olivia', 'Garcia', '551112345678', 'olivia.garcia@garciatechnologies.net', 'F', 42, '9/AHLANA(N)987601'),
	('C-00009','Ava', 'Robinson', '61212345678', 'ava.robinson@robinsonenterprises.com', 'F', 33, '6/AHLANA(N)342198'),
	('C-00010','Mia', 'Anderson', '74951234567', 'mia.anderson@andersonsolutions.net', 'F', 28, '7/YAMAKA(N)654327'),
	('C-00011','Robert', 'Pattinson', '27111234567', 'robertpattison@acting.uk', 'M', 20, '5/YAMAKA(N)638394'),
	('C-00012','Bo Bo', 'Thaw', '959759803723', 'bbthaw1@kmd.edu.mm', 'M', 19, '12/AHLANA(N)051486');

Select * from Customers

Insert Into Staff (StaffID, StaffName, StaffPhone, StaffEmail, StaffAddress, StaffNRC)
Values ('S-00001', 'John Doe', '1234567890', 'john.doe@stardusthotel.mm', '123 Main St, Yangon, Myanmar', '6/OUKAMA(N)385421'),
  ('S-00002', 'Jane Smith', '9876543210', 'jane.smith@stardusthotel.mm', '456 Elm St, Myeik, Myanmar', '7/KAHANN(N)903176'),
  ('S-00003', 'Michael Brown', '5555555555', 'michael.brown@stardusthotel.mm', '789 Oak St, Dawei, Myanmar', '8/GHJAGHA(N)642859'),
  ('S-00004', 'Emily Johnson', '1112223333', 'emily.johnson@stardusthotel.mm', '101 Pine St, Naypyidaw, Myanmar', '9/NGCAJHA(N)217504'),
  ('S-00005', 'Ethan Wilson', '9990001111', 'ethan.wilson@stardusthotel.mm', '222 Cedar St, Bago, Myanmar', '10/JHJHAKA(N)765432'),
  ('S-00006', 'Olivia Garcia', '7778889999', 'olivia.garcia@stardusthotel.mm', '333 Birch St, Mandalay, Myanmar', '11/CAHANN(N)129875'),
  ('S-00007', 'Ava Robinson', '4445556666', 'ava.robinson@stardusthotel.mm', '444 Maple St, Myeik, Myanmar', '12/KHJAGHA(N)506734'),
  ('S-00008', 'Mia Anderson', '6663339999', 'mia.anderson@stardusthotel.mm', '555 Redwood St, Yangon, Myanmar', '13/GAGHJKA(N)987601'),
  ('S-00009', 'Sophia Davis', '2224446666', 'sophia.davis@stardusthotel.mm', '666 Spruce St, Dawei, Myanmar', '14/GHKAGHA(N)342198'),
  ('S-00010', 'Robert Brown', '8887776666', 'robert.brown@stardusthotel.mm', '777 Sequoia St, Bago, Myanmar', '15/JAGHJKA(N)654327');

Select * from Staff

Insert Into Occupants (OccupantID, OccupantName, Email, Phone, Gender, Age)
Values
  ('OCU-00001', 'Walter White', 'walter.w@gmail.com', '5556667777', 'M', 50),
  ('OCU-00002', 'Jesse Pinkman', 'jesse.p@yahoo.com', '3336669999', 'M', 28),
  ('OCU-00003', 'Skyler White', 'skyler.w@gmail.com', '2223334444', 'F', 45),
  ('OCU-00004', 'Hank Schrader', 'hank.s@gmail.com', '1112223333', 'M', 47),
  ('OCU-00005', 'Marie Schrader', 'marie.s@yahoo.com', '9998887777', 'F', 41),
  ('OCU-00006', 'Gus Fring', 'gus.f@gmail.com', '7778889999', 'O', 55),
  ('OCU-00007', 'Saul Goodman', 'saul.g@yahoo.com', '8885556666', 'M', 45),
  ('OCU-00008', 'Mike Ehrmantraut', 'mike.e@gmail.com', '4446667777', 'M', 60),
  ('OCU-00009', 'Tuco Salamanca', 'tuco.s@yahoo.com', '3339998888', 'M', 35),
  ('OCU-00010', 'Lydia Rodarte-Quayle', 'lydia.r@gmail.com', '2227778888', 'F', 40),
  ('OCU-00011', 'Hector Salamanca', 'hector.s@yahoo.com', '5554443333', 'M', 70),
  ('OCU-00012', 'Gale Boetticher', 'gale.b@gmail.com', '6667778888', 'O', 35),
  ('OCU-00013', 'Kim Wexler', 'kim.w@yahoo.com', '4449996666', 'F', 38),
  ('OCU-00014', 'Nacho Varga', 'nacho.v@gmail.com', '3337775555', 'M', 30),
  ('OCU-00015', 'Holly White', 'holly.w@gmail.com', '', 'F', 3);

Alter table Occupants 
Drop Constraint CK__Occupants__Phone__59063A47

Alter table Occupants
Add Constraint CK__Occupants__Phone Check (Phone not like '%[^0-9]%'); 

Select * from Customers

Select * from Reservations

Insert Into Reservations (ReservationID, ReservationStartDate, CustomerID, StaffID)
Values ('Rer-00001', '2023-08-25', 'C-00001', 'S-00001'),
  ('Rer-00002', '2023-09-05', 'C-00002', 'S-00002'),
  ('Rer-00003', '2023-09-12', 'C-00003', 'S-00003'),
  ('Rer-00004', '2023-09-20', 'C-00005', 'S-00004'),
  ('Rer-00005', '2023-10-01', 'C-00005', 'S-00005'),
  ('Rer-00006', '2023-10-15', 'C-00008', 'S-00006'),
  ('Rer-00007', '2023-10-22', 'C-00007', 'S-00007'),
  ('Rer-00008', '2023-11-03', 'C-00008', 'S-00008'),
  ('Rer-00009', '2023-11-12', 'C-00009', 'S-00009'),
  ('Rer-00010', '2023-11-20', 'C-00010', 'S-00008'),
  ('Rer-00011', '2023-12-05', 'C-00010', 'S-00001'),
  ('Rer-00012', '2023-12-10', 'C-00012', 'S-00002'),
  ('Rer-00013', '2023-12-20', 'C-00010', 'S-00001'),
  ('Rer-00014', '2023-12-25', 'C-00011', 'S-00003'),
  ('Rer-00015', '2024-01-05', 'C-00010', 'S-00001');

Insert Into Occupations(OccupationID, ReservationID, RoomID, CheckInDateTime, CheckOutDateTime)
Values
  ('O-00001', 'Rer-00001','R-00001', '2023-08-25 14:00:00', '2023-08-28 11:00:00'),
  ('O-00002', 'Rer-00001','R-00002', '2023-08-25 14:00:00', '2023-08-28 11:00:00'),
  ('O-00003', 'Rer-00001','R-00003', '2023-08-25 14:00:00', '2023-08-28 11:00:00'),
  ('O-00004', 'Rer-00001','R-00004', '2023-08-25 14:00:00', '2023-08-28 11:00:00'),
  ('O-00005', 'Rer-00002','R-00015', '2023-09-05 15:30:00', '2023-09-08 12:00:00'),
  ('O-00006', 'Rer-00002','R-00006', '2023-09-05 15:30:00', '2023-09-08 12:00:00'),
  ('O-00007', 'Rer-00002','R-00007', '2023-09-05 15:30:00', '2023-09-08 12:00:00'),
  ('O-00008', 'Rer-00002','R-00018', '2023-09-05 15:30:00', '2023-09-08 12:00:00'),
  ('O-00009', 'Rer-00003','R-00009', '2023-09-12 12:00:00', '2023-09-15 10:00:00'),
  ('O-00010', 'Rer-00004','R-00010', '2023-09-20 14:00:00', '2023-09-23 11:30:00'),
  ('O-00011', 'Rer-00005','R-00011', '2023-10-01 10:00:00', '2023-10-04 09:00:00'),
  ('O-00012', 'Rer-00006','R-00021', '2023-10-15 13:00:00', '2023-10-18 10:30:00');


Insert into Occupation_List(OccupationID, OccupantID)
Values 
	('O-00001', 'OCU-00001'),
	('O-00001', 'OCU-00002'),
	('O-00002', 'OCU-00003'),
	('O-00002', 'OCU-00004'),
	('O-00003', 'OCU-00006'),
	('O-00003', 'OCU-00005'),
	('O-00004', 'OCU-00006'),
	('O-00004', 'OCU-00007'),
	('O-00005', 'OCU-00008'),
	('O-00006', 'OCU-00009'),
	('O-00007', 'OCU-00010'),
	('O-00008', 'OCU-00011'),
	('O-00008', 'OCU-00012'),
	('O-00009', 'OCU-00013'),
	('O-00010', 'OCU-00014'),
	('O-00011', 'OCU-00001'),
	('O-00011', 'OCU-00002'),
	('O-00012', 'OCU-00015');

Select * from Occupation_List

INSERT INTO PaymentTypes (PaymentTypeID, PaymentTypeName)
VALUES
  ('PT-00001', 'Credit Card'),
  ('PT-00002', 'Cash'),
  ('PT-00003', 'Debit Card'),
  ('PT-00004', 'PayPal'),
  ('PT-00005', 'Bank Transfer');

Select * from PaymentTypes
Delete from Payments
INSERT INTO Payments (ReservationID, PaymentAmount, PaymentTypeID)
VALUES
  ('Rer-00001', 1.00, 'PT-00001'),
  ('Rer-00002', 1.00, 'PT-00003'),
  ('Rer-00003', 1.00, 'PT-00001'),
  ('Rer-00004', 1.00, 'PT-00002'),
  ('Rer-00005', 1.00, 'PT-00001'),
  ('Rer-00006', 1.00, 'PT-00001');

Select * from Payments

Select * from Reservations






Insert into Room_Reservation (ReservationID, RoomID, Cancelled)
Values 
	('Rer-00001', 'R-00001', 0),
	('Rer-00001', 'R-00002', 0),
	('Rer-00001', 'R-00003', 0),
	('Rer-00001', 'R-00004', 0),
	('Rer-00002', 'R-00015', 0),
	('Rer-00002', 'R-00006', 0),
	('Rer-00002', 'R-00007', 0),
	('Rer-00002', 'R-00018', 0),
	('Rer-00003', 'R-00009', 0),
	('Rer-00003', 'R-00010', 1),
	('Rer-00004', 'R-00010', 0),
	('Rer-00005', 'R-00011', 0),
	('Rer-00006', 'R-00021', 0),
	('Rer-00007', 'R-00001', 0),
	('Rer-00007', 'R-00011', 0),
	('Rer-00008', 'R-00001', 0),
	('Rer-00008', 'R-00002', 1),
	('Rer-00009', 'R-00001', 0),
	('Rer-00010', 'R-00021', 0),
	('Rer-00011', 'R-00020', 1),
	('Rer-00012', 'R-00018', 1),
	('Rer-00013', 'R-00021', 1),
	('Rer-00014', 'R-00017', 0),
	('Rer-00014', 'R-00019', 0),
	('Rer-00015', 'R-00009', 0);

---Each Reservation's Total Price---
Select  o.ReservationID, Sum(rt.Price * (DATEDIFF(DAY, o.CheckInDateTime, o.CheckOutDateTime))) AS TotalPrice 
From Occupations o
Inner Join Room_Reservation rr on rr.ReservationID = o.ReservationID
AND rr.RoomID = o.RoomID
Inner Join Rooms r on rr.RoomID = r.RoomID 
Inner Join Reservations rer on rer.ReservationID = rr.ReservationID
Inner Join RoomTypes rt on rt.RoomTypeID = r.RoomTypeID
Group by  o.ReservationID, o.CheckInDateTime, o.CheckOutDateTime
-------------------------------------


---Each Occupation's Total Price-------
Select  o.OccupationID, (SUM(rt.Price * (DATEDIFF(DAY, o.CheckInDateTime, o.CheckOutDateTime)))) AS TotalPrice 
From Occupations o
Inner Join Room_Reservation rr on rr.ReservationID = o.ReservationID
AND rr.RoomID = o.RoomID
Inner Join Rooms r on rr.RoomID = r.RoomID 
Inner Join Reservations rer on rer.ReservationID = rr.ReservationID
Inner Join RoomTypes rt on rt.RoomTypeID = r.RoomTypeID
Group by   o.OccupationID
----------------------------------------

---Total Reservations of each Customer--
Select c.Email, COUNT (r.ReservationID) as TotalReservations
From Customers c
Inner Join Reservations r on r.CustomerID = c.CustomerID
Group by  c.Email, r.ReservationID
Order By COUNT(r.ReservationID) DESC
---------------------------------------

--Each Customer's Total Reserved Rooms--
SELECT c.CustomerID, c.Email, SUM(RoomCounts.TotalRoomsInReservation) AS TotalRoomsReserved
FROM Customers c
Inner JOIN Reservations r ON r.CustomerID = c.CustomerID

Left JOIN (
    SELECT r.ReservationID, COUNT(rr.RoomID) AS TotalRoomsInReservation
    FROM Reservations r
    INNER JOIN Room_Reservation rr ON r.ReservationID = rr.ReservationID
    GROUP BY r.ReservationID
) AS RoomCounts ON r.ReservationID = RoomCounts.ReservationID
GROUP BY c.Email,  c.CustomerID
Order By CustomerID
----------

---Amentity count in each room---
Select a.AmenityName, COUNT(ar.AmenityID) as AmentiyCount
From Amenities a
Inner Join Amenity_RoomType ar on ar.AmenityID = a.AmenityID
Inner Join RoomTypes rt on rt.RoomTypeID = ar.RoomTypeID
Inner Join Rooms r on rt.RoomTypeID = r.RoomTypeID
Group By a.AmenityName
Order By COUNT(ar.AmenityID) DESC
---------------------------------

---Customers with no reservations---
Select c.CustomerID, c.FirstName, c.LastName, c.Email
From Customers c
Left Join Reservations r on r.CustomerID = c.CustomerID
Group By c.CustomerID, c.FirstName, c.LastName, c.Email
Having Count (r.ReservationID) = 0
-------------------------------------

---
Select ocu.OccupantName, ocu.Age, o.OccupationID, o.ReservationID, o.RoomID, rt.RoomTypeName
From RoomTypes rt
Inner Join Rooms r on r.RoomTypeID = rt.RoomTypeID
Inner Join Room_Reservation rr on rr.RoomID = r.RoomID
Inner Join Reservations rer on rer.ReservationID = rr.ReservationID
Inner Join Occupations o on o.ReservationID = rr.ReservationID
AND o.RoomID = rr.RoomID
Inner Join Occupation_List ol on ol.OccupationID = o.OccupationID
Inner Join Occupants ocu on ocu.OccupantID = ol.OccupantID
Order By RoomTypeName


--- Average Age of Occupants Stayed in Each Room Type ----
Select rt.RoomTypeName, AVG(ocu.Age) AS AverageOccupantAge
From RoomTypes rt
Inner Join Rooms r on r.RoomTypeID = rt.RoomTypeID
Inner Join Room_Reservation rr on rr.RoomID = r.RoomID
Inner Join Reservations rer on rer.ReservationID = rr.ReservationID
Inner Join Occupations o on o.ReservationID = rr.ReservationID
AND o.RoomID = rr.RoomID
Inner Join Occupation_List ol on ol.OccupationID = o.OccupationID
Inner Join Occupants ocu on ocu.OccupantID = ol.OccupantID
Group By rt.RoomTypeName
----------------------------------------------------------

--- RoomCounts of Each Room Type --------
Select rt.RoomTypeName, COUNT(r.RoomID) AS RoomCounts
From RoomTypes rt
Left Join Rooms r on r.RoomTypeID = rt.RoomTypeID
Group By rt.RoomTypeName
-----------------------------------------


---- Total Money Spent By Customers In this hotel ----
Select c.FirstName, c.LastName, c.Email,SUM(ReservationTotalPrice.TotalPrice) AS TotalSpentAmount
From Customers c
Left Join Reservations r on r.CustomerID = c.CustomerID
Left Join (Select  o.ReservationID, Sum(rt.Price * (DATEDIFF(DAY, o.CheckInDateTime, o.CheckOutDateTime))) AS TotalPrice 
From Occupations o
Inner Join Room_Reservation rr on rr.ReservationID = o.ReservationID
AND rr.RoomID = o.RoomID
Inner Join Rooms r on rr.RoomID = r.RoomID 
Inner Join Reservations rer on rer.ReservationID = rr.ReservationID
Inner Join RoomTypes rt on rt.RoomTypeID = r.RoomTypeID
Group by  o.ReservationID, o.CheckInDateTime, o.CheckOutDateTime) AS ReservationTotalPrice on ReservationTotalPrice.ReservationID = r.ReservationID
Group By c.FirstName, c.LastName, c.Email
Order By TotalSpentAmount DESC
--------------------------------------------------------


--- Hotel's Yearly Earnings ---
Select YEAR(o.CheckOutDateTime) AS YEAR, SUM(OccupationsTotal.TotalPrice) AS YearsEarnings
From Occupations o
Inner Join (Select  o.OccupationID,  SUM(rt.Price * (DATEDIFF(DAY, o.CheckInDateTime, o.CheckOutDateTime))) AS TotalPrice 
From Occupations o
Inner Join Room_Reservation rr on rr.ReservationID = o.ReservationID
AND rr.RoomID = o.RoomID
Inner Join Rooms r on rr.RoomID = r.RoomID 
Inner Join Reservations rer on rer.ReservationID = rr.ReservationID
Inner Join RoomTypes rt on rt.RoomTypeID = r.RoomTypeID
Group by   o.OccupationID) AS OccupationsTotal on OccupationsTotal.OccupationID = o.OccupationID
Group By YEAR(o.CheckOutDateTime)
-------------------------------

-----Each Room Type Available Rooms-------
Select rt.RoomTypeName, COUNT(r.RoomID) AS AvailableRooms 
From RoomTypes rt 
Left Join Rooms r On r.RoomTypeID = rt.RoomTypeID
AND r.Occupied_Status = 0
Group By rt.RoomTypeName
--------------------------------------------

Select RoomTypeName AS Unavailable_Rooms
From (Select rt.RoomTypeName, COUNT(r.RoomID) AS AvailableRooms 
From RoomTypes rt 
Left Join Rooms r On r.RoomTypeID = rt.RoomTypeID
AND r.Occupied_Status = 0
Group By rt.RoomTypeName) AS AvailableRoomCounts
Where AvailableRoomCounts.AvailableRooms = 0

Select s.StaffName, s.StaffEmail, COUNT(r.ReservationID) AS Total_Handled_Reservations
From Reservations r
Right Join Staff s On r.StaffID = s.StaffID 
Group By s.StaffName, s.StaffEmail
Order By COUNT(r.ReservationID) DESC







Select * from Rooms Where RoomTypeID = 'RT-00007'
Select * from RoomTypes



-----

Select * from Reservations
Select * from Room_Reservation
Select * from Occupations

Insert into Occupations(OccupationID, ReservationID, RoomID, CheckInDateTime, CheckOutDateTime)
Values ('O-00013', 'Rer-00015', 'R-00009', '2024-1-06 13:00:00.000', '2024-1-09 13:00:00.000')

Insert into Payments
Values ('Rer-00015', 1.00, 'PT-00005')

Delete from Payments
WHere ReservationID = 'Rer-00015'

Delete from Occupations Where OccupationID = 'O-00013'

Select pt.PaymentTypeName, COUNT(p.ReservationID) AS MethodsCount
From PaymentTypes pt
Left Join Payments p ON p.PaymentTypeID = pt.PaymentTypeID
Group By pt.PaymentTypeName

Select * from Payments

Select * from Amenities
Select * from RoomTypes
Select * from Amenity_RoomType
Order By RoomTypeID

Select * from Rooms



Select c.CustomerID, c.FirstName, c.LastName, r.ReservationID, rr.RoomID
From Customers c
Inner Join Reservations r on c.CustomerID = r.CustomerID
Inner Join Room_Reservation rr on r.ReservationID = rr.ReservationID
ORder by c.CustomerID


Select * from Reservations
Select * from Room_Reservation







