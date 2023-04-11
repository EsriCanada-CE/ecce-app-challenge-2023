import QtQuick 2.0

Item {

    function getDate(timestamp)
    {
        var date = new Date(timestamp);
        var jsDateValues = [
                    date.getMonth()+1,
                    date.getDate(),
                    date.getFullYear()
                ]
        return jsDateValues.join("/")
    }

}
