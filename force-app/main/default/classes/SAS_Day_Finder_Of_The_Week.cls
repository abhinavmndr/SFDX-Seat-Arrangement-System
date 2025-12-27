public with sharing class SAS_Day_Finder_Of_The_Week {

    public static String getDayName(Date inputDate) {

        // Known reference date: 1 Jan 2000 = Saturday
        Date referenceDate = Date.newInstance(2025, 12, 3);
        Integer referenceDayIndex = 3; // Saturday (0=Sunday, 1=Monday...6=Saturday)

        // Calculate difference between the dates
        Integer diff = (referenceDate.daysBetween(inputDate));
        

        // Determine weekday index using modulo 7
        Integer dayIndex = Math.mod((referenceDayIndex + diff), 7);
        if(dayIndex < 0){
            dayIndex = dayIndex + 7;
        }
        System.debug(dayIndex);

        // Map index to day name
        List<String> days = new List<String>{
            'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'
        };
		//System.assert(false,days[dayIndex]);
        return days[dayIndex];
    }
}