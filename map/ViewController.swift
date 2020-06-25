//
//  ViewController.swift
//  map
//
//  Created by 井上知貴 on 2020/06/24.
//  Copyright © 2020 井上知貴. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class ViewController: UIViewController {
    @IBOutlet weak var mapView: MKMapView!
    var locationManager: CLLocationManager!
    
    let pinImagges: [UIImage?] = [UIImage(named: "inu1"),UIImage(named: "inu2")]
    let pinTitles: [String] = ["白いい犬","茶色い犬"]
    let pinSubTiiles: [String] = ["比較的白いです","茶色いのが売りです"]
    let pinlocations: [CLLocationCoordinate2D] = [CLLocationCoordinate2DMake(35.68, 139.56),CLLocationCoordinate2DMake(35.70, 139.56)]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // ロケーションマネージャーのセットアップ
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager!.requestWhenInUseAuthorization()
        
        mapView.delegate = self
        mapView.userTrackingMode = MKUserTrackingMode.follow
        
        // 現在地に照準を合わす
        let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        let region = MKCoordinateRegion(center: mapView.userLocation.coordinate, span: span)
        mapView.region = region
        
        // 指定値にピンを立てる
//        let coordinate = CLLocationCoordinate2DMake(35.68, 139.56)
        let coordinate = mapView.userLocation.coordinate
        let pin = MKPointAnnotation()
        pin.title = "タイトル"
        pin.subtitle = "サブタイトル"
        
        pin.coordinate = coordinate
        mapView.addAnnotation(pin)
        
        // カスタムの設定
        for (index,pinTitle) in self.pinTitles.enumerated() {
            let coordinate = self.pinlocations[index]
            let pin = MapAnnotationSetting()
            pin.title = pinTitle
            pin.subtitle = self.pinSubTiiles[index]
            pin.coordinate = coordinate
            pin.pinImage = pinImagges[index]
            self.mapView.addAnnotation(pin)
        }
        
        // ロングタップを検知
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(recognizeLongPress(sender:)))
        //MapViewにリスナーを登録
        self.mapView.addGestureRecognizer(longPress)
    }
    
    @IBAction func tap(_ sender: Any) {
        
        geoCording()
        reverseGeoCording()
        
    }
    
    // 逆ジオコーデインング
    func reverseGeoCording() {
        let location = CLLocation(latitude: 35.681236, longitude: 139.767125)
        CLGeocoder().reverseGeocodeLocation(location) { placemarks, error in
            guard let placemark = placemarks?.first, error == nil else { return }
            
            print(placemark.name!)
            print(placemark.administrativeArea!)
            print(placemark.subAdministrativeArea ?? "")
            print(placemark.locality!)
            print(placemark.administrativeArea! + placemark.locality! + placemark.name!)
        }
    }
    
    
    // ジオコーディング(住所から緯度・経度)
    func geoCording() {
        let address = "東京都千代田区丸の内１丁目"
        var reaultlat: CLLocationDegrees!
        var resultlng: CLLocationDegrees!
        CLGeocoder().geocodeAddressString(address) { placemarks, error in
            if let lat = placemarks?.first?.location?.coordinate.latitude {
                print("緯度 : \(lat)")
                reaultlat = lat
                
            }
            if let lng = placemarks?.first?.location?.coordinate.longitude {
                print("経度 : \(lng)")
                resultlng = lng
            }
            
            if (resultlng != nil && reaultlat != nil) {
                let cordinate = CLLocationCoordinate2DMake(reaultlat, resultlng)
                let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                let region = MKCoordinateRegion(center: cordinate, span: span)
                self.mapView.region = region
                
                // 指定値にピンを立てる
                let pin = MKPointAnnotation()
                pin.title = "タイトル"
                pin.subtitle = "サブタイトル"
                
                pin.coordinate = cordinate
                self.mapView.addAnnotation(pin)
            }
        }
    }
    
    //長押し時の処理
    @objc func recognizeLongPress(sender: UILongPressGestureRecognizer) {
        //長押し感知は最初の1回のみ
        if sender.state != UIGestureRecognizer.State.began {
            return
        }
        
        let location = sender.location(in: self.mapView)
        let coordinate = self.mapView.convert(location, toCoordinateFrom: self.mapView)
        print(coordinate.latitude)
        print(coordinate.longitude)
        let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        let region = MKCoordinateRegion(center: coordinate, span: span)
        self.mapView.region = region
        
        
        let pin = MKPointAnnotation()
        pin.title = "タイトル"
        pin.subtitle = "サブタイトル"
        
        pin.coordinate = coordinate
        self.mapView.addAnnotation(pin)
    }
}

extension ViewController:CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .restricted, .denied:
            break
        case .authorizedAlways, .authorizedWhenInUse:
            manager.startUpdatingLocation()
            break
        default:
            break
        }
    }
}

extension ViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        // 自分の現在地は置き換えない
        if (annotation is MKUserLocation) {
            return nil
        }
        
        let identifier = "pin"
        var annotationView: MKAnnotationView!

        if annotationView == nil {
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
        }
        
        if let pin = annotation as? MapAnnotationSetting {
            if let pinImage = pin.pinImage {
               annotationView.image = pinImage
            }
        }
        annotationView.annotation = annotation
        annotationView.canShowCallout = true

        return annotationView
    }
    
    // ピンが選択された時の挙動
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        let storyboard:UIStoryboard! = self.storyboard!
        let next = storyboard.instantiateViewController(identifier: "foo") as SecondViewController
        self.present(next,animated: true,completion: nil)
        // タップされたピンの位置情報
        print(view.annotation?.coordinate)
        // タップされたピンのタイトルとサブタイトル
        print(view.annotation?.title)
        print(view.annotation?.subtitle)
    }
}

class MapAnnotationSetting: MKPointAnnotation {
    // デフォルトだとタイトル・サブタイトルしかないので、設定を追加する
    var pinImage: UIImage?
}
