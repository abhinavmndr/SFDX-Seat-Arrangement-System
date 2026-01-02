@isTest
public class SAS_Test_Day_Finder_Of_The_Week {
	
    @IsTest
    public static void givenReferenceDate_WhenGetDayName_ThenCorrectDayReturned() {

        // Reference date used in class: 3 Dec 2025
        Date referenceDate = Date.newInstance(2025, 12, 3);

        String dayName = SAS_Day_Finder_Of_The_Week.getDayName(referenceDate);

        System.assertEquals('Wednesday', dayName,'Reference date should return Wednesday');
    }

    @IsTest
    public static void givenFutureDate_WhenGetDayName_ThenCorrectDayReturned() {

        // 4 Dec 2025 → Thursday
        Date futureDate = Date.newInstance(2025, 12, 4);

        String dayName = SAS_Day_Finder_Of_The_Week.getDayName(futureDate);

        System.assertEquals('Thursday',dayName,'Future date should return Thursday' );
    }

    @IsTest
    public static void givenPastDate_WhenModuloIsNegative_ThenCorrectDayReturned() {

        // 1 Jan 2025 → Wednesday
        Date farPastDate = Date.newInstance(2025, 1, 1);

        String dayName = SAS_Day_Finder_Of_The_Week.getDayName(farPastDate);

        System.assertEquals('Wednesday',dayName,'Negative modulo handling should return correct weekday');
    }
}