contract DateTimeAPI {
        /*
         *  Abstract contract for interfacing with the DateTime contract.
         *
         */
         
        struct _DateTime {
                uint16 year;
                uint8 month;
                uint8 day;
                uint8 hour;
                uint8 minute;
                uint8 second;
                uint8 weekday;
        } 
         
        function isLeapYear(uint16 year) public pure returns (bool);
        function leapYearsBefore(uint year) public pure returns (uint);
        function getDaysInMonth(uint8 month, uint16 year) public pure returns (uint8);
        function parseTimestamp(uint timestamp) internal pure returns (_DateTime dt);
        function getYear(uint timestamp) public pure returns (uint16);
        function getMonth(uint timestamp) public pure returns (uint8);
        function getDay(uint timestamp) public pure returns (uint8);
        function getHour(uint timestamp) public pure returns (uint8);
        function getMinute(uint timestamp) public pure returns (uint8);
        function getSecond(uint timestamp) public pure returns (uint8);
        function getWeekday(uint timestamp) public pure returns (uint8);
        function toTimestamp(uint16 year, uint8 month, uint8 day) public constant returns (uint timestamp);
        function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour) public constant returns (uint timestamp);
        function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour, uint8 minute) public constant returns (uint timestamp);
        function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour, uint8 minute, uint8 second) public constant returns (uint timestamp);
}