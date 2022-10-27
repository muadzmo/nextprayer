// main.qml
import QtQuick 2.15
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.components 3.0 as PlasmaComponents
import org.kde.plasma.core 2.0 as PlasmaCore
import QtQuick.Layouts 1.3

Item {
    id: "root"
    property int minWidth : 200 // it will be changed to nextPray.length * 8
    Layout.minimumWidth: minWidth + 30 // +30 will be function like margin
    anchors{
        bottomMargin: 2
    }
    property string nextPray : "No Data :(";
    property string city: Plasmoid.configuration.city

    function getJadwalSholat(){
        const today = new Date();
        var a = "subuh";
        var base_url = `https://api.myquran.com/v1/sholat/jadwal/1108/${today.getFullYear()}/${today.getMonth()+1}/${today.getDate()}`; //1108 for Tangerang Selatan, for another city in Indonesia, go https://api.myquran.com/v1/sholat/kota/semua 
        var URL = base_url
        request(URL, function (o) {
            if (o.status === 200){
                var jadwal = JSON.parse(o.response).data.jadwal;
                jadwalSholat.subuh = jadwal.subuh
                jadwalSholat.dzuhur =  jadwal.dzuhur
                jadwalSholat.ashar = jadwal.ashar
                jadwalSholat.maghrib = jadwal.maghrib
                jadwalSholat.isya = jadwal.isya
                jadwalSholat.tanggal = jadwal.date
            }else{
                console.log("Some error has occurred:",o);
            }
        });
        return jadwalSholat
    }

    QtObject {
        id : "jadwalSholat"
        property string subuh: "04:00"
        property string dzuhur: "12:00"
        property string ashar: "15:00"
        property string maghrib: "18:00"
        property string isya: "19:00"
        property string tanggal: "ini tanggal"
    }
    QtObject {
        id: "prayerTime"
        property string lastthird:  "00:00"
        property string imsak:      "00:00"
        property string fajr:       "00:00"
        property string sunrise:    "00:00"
        property string dhuhr:      "00:00"
        property string asr:        "00:00"
        property string maghrib:    "00:00"
        property string sunset:     "00:00"
        property string isha:       "00:00"
        property string midnight:   "00:00"
        property string firstthird: "00:00"
        property string date:  "32 Aug 2022"
        property string latlong:  ""
    }
    // property var jadwalSholat : getJadwalSholat()
    property var jadwalSholat : getSchedule(plasmoid.configuration.city)

    function getSchedule(city) {
        if ( !city ){
            console.log("Enter Location First");
            return
        }
        // const today = new Date();
        // const formattedDate = `${today.getDate()}-${today.getMonth()+1}-${today.getFullYear()}`
        // var base_url = `https://dailyprayer.abdulrcs.repl.co/api/`; 
        // var base_url = `https://api.aladhan.com/v1/timings/${formattedDate}?latitude=51.508515&longitude=-0.1254872&method=2`; 
        // var base_url = `https://muslimsalat.com/daily/tangerang selatan/false.json`; 
        // var base_url = `https://api.myquran.com/v1/sholat/jadwal/1108/${today.getFullYear()}/${today.getMonth()+1}/${today.getDate()}`;
        // var base_url = `https://dailyprayer.abdulrcs.repl.co/api/${city}`;
        var base_url = `http://api.aladhan.com/v1/timingsByAddress?address=${city}`;
        var URL = `${base_url}`
        console.log(base_url)
        request(URL, function (o) {
            var resp = JSON.parse(o.response);
            if( o.status === 200 ){
                for ( var key in resp.data.timings ){
                    var fixKey = key.toLocaleLowerCase();
                    var prefix = "";
                    if( fixKey == "fajr" || fixKey == "sunrise" || fixKey == "imsak" ) { prefix = `  `}
                    if( fixKey == "dhuhr" ) { prefix = `  ` }
                    if( fixKey == "asr" ) { prefix = `  ` }
                    if( fixKey == "sunset" || fixKey == "maghrib" ) { prefix = `滋  ` }
                    if( fixKey == "isha" || fixKey == "midnight" || fixKey == "firstthird" || fixKey == "lastthird" ) { prefix = ` ` }
                    prefix += `${key}`
                    prayerTime[fixKey] = `${prefix} ${resp.data.timings[key]}`
                }
                prayerTime["date"] = resp.data.date.readable
                prayerTime["latlong"] = `${resp.data.meta.latitude},${resp.data.meta.longitude}`
            }else{
                console.log("Something went wrong:",resp.data)
            }
        });
        return prayerTime
    }

    property string wadaw : doConsole(jadwalSholat, jadwalSholat)
    property string wadaw2 : doConsole(prayerTime.Fajr, "prayerTime")

    function doConsole(a,b){
        console.log("101:",a, b, plasmoid.configuration.latitude, plasmoid.configuration.longitude)
        return "wadaw"
    }

    function request(url, callback) {
        var xhr = new XMLHttpRequest();
        xhr.onreadystatechange = (function(myxhr) {
            return function() {
                if(myxhr.readyState === 4) { callback(myxhr); }
            }
        })(xhr);

        xhr.open("GET", url);
        xhr.send();
    }

    PlasmaCore.DataSource {
        id: dataSource
        engine: "time"
        connectedSources: "Local"
        interval: prayerTime.latlong === "" ? 1000 : 30000
        onDataChanged: {
            if( !plasmoid.configuration.city ){
                nextPray = "Select Location First"
                return
            }

            var date = new Date(data["Local"]["DateTime"]);
            var hours = date.getHours();
            var minutes = date.getMinutes();
            var seconds = date.getSeconds();            

            var strHours = hours > 9 ? hours : `0${hours}`
            var strMinutes = minutes > 9 ? minutes : `0${minutes}`
            var currentTime = `${strHours}:${strMinutes}`
            nextPray = "Loading Data.."
            for( var key in prayerTime ){
                var realTime = prayerTime[key].split(" ")[prayerTime[key].split(" ").length-1]
                if ( key == "date" || key == "latlong" || key == "objectName" ){
                    continue;
                }
                
                if ( currentTime < realTime ){
                    nextPray = prayerTime[key];
                    break;
                }
            }
            minWidth = nextPray.length * 8
        }
        Component.onCompleted: {
            onDataChanged();
        }
    }

    PlasmaCore.ToolTipArea {
        anchors{
            fill: parent
        }
        Layout.minimumHeight: 1000
        mainText: i18n(`Prayer Time`)
        subText: {
            var details = ``
            for (var key in prayerTime) {
                if( prayerTime[key] == "" ){
                    continue
                }
                details += `${prayerTime[key]} | `
                if( key == "latlong" ){
                    break;
                }
            }
            return details
        }
    }

    PlasmaComponents.Label {
        anchors.centerIn: root
        text: `${nextPray}`
        Plasmoid.preferredRepresentation: Plasmoid.fullRepresentation
    }
}
