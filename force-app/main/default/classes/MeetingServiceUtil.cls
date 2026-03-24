public with sharing class MeetingServiceUtil {
    public static DateTime parseDateTime(String dateTimeStr) {
        String dtString = dateTimeStr.replace('T', ' ');

        // Convert the string to DateTime
        DateTime dt = DateTime.valueOfGMT(dtString);

        return dt;
    }
    

}