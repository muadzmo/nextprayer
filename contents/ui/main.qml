// main.qml
import QtQuick 2.15
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.components 3.0 as PlasmaComponents
import org.kde.plasma.core 2.0 as PlasmaCore
import QtQuick.Layouts 1.3

Item {
    id: "root"
    Layout.minimumWidth: 80
    anchors{
        bottomMargin: 4
    }
    property string nextPray : "Nope :)";

    function getJadwalSholat(){
        const today = new Date();
        var a = "subuh";
        var base_url = `https://api.myquran.com/v1/sholat/jadwal/1108/${today.getFullYear()}/${today.getMonth()+1}/${today.getDate()}`;
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
    property var jadwalSholat : getJadwalSholat()

    property string wadaw : doConsole(jadwalSholat)

    function doConsole(a,b){
        console.log("jadwal:",a.tanggal, a.subuh, a.dzuhur, a.ashar, a.maghrib, a.isya, b)
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
        interval: 30000
        onDataChanged: {
            var date = new Date(data["Local"]["DateTime"]);
            var hours = date.getHours();
            var minutes = date.getMinutes();
            var seconds = date.getSeconds();

            var strHours = hours > 9 ? hours : `0${hours}`
            var strMinutes = minutes > 9 ? minutes : `0${minutes}`
            var currentTime = `${strHours}:${strMinutes}`
            nextPray = "Unknown 00:00"
            if( currentTime < jadwalSholat.subuh ){
                nextPray = `🌅 ${jadwalSholat.subuh}`
            }else if ( currentTime < jadwalSholat.dzuhur ){
                nextPray = `☀️ ${jadwalSholat.dzuhur}`
            }else if ( currentTime < jadwalSholat.ashar ){
                nextPray = `⛱️ ${jadwalSholat.ashar}`
            }else if ( currentTime < jadwalSholat.maghrib ){
                nextPray = `🌇 ${jadwalSholat.maghrib}`
            }else if ( currentTime < jadwalSholat.isya ){
                nextPray = `🌃 ${jadwalSholat.isya}`
            }else if ( currentTime > jadwalSholat.isya ){
                nextPray = "🙃"
            }
        }
        Component.onCompleted: {
            onDataChanged();
        }
    }

    PlasmaCore.ToolTipArea {
        anchors.fill: parent
        width: 200
        mainText: i18n(`Jadwal Sholat`)
        subText: {
            var details = ``
            for (var key in jadwalSholat) {
                if( jadwalSholat[key] == "" ){
                    continue
                }
                var repairedKey = `${key.charAt().toLocaleUpperCase()}${key.replace(key.charAt(),"")}`
                details += `${repairedKey} : ${jadwalSholat[key]} <br>`
                if ( key == "tanggal"){
                    break
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
