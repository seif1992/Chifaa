//
//  MainViewController.swift
//  Chifaa
//
//  Created by Seif eddinne meddeb on 3/9/18.
//  Copyright © 2018 Seif eddinne meddeb. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

protocol detailsVc {
    func navigateDetailsMap(index : Int)
}

class MainViewController: UIViewController,CLLocationManagerDelegate,MKMapViewDelegate,UITableViewDelegate,UITableViewDataSource,detailsVc{
    
    @IBOutlet weak var infoBtn: UIButton!
    @IBOutlet weak var localBtn: UIButton!
    
    @IBOutlet weak var listBtn: UIButton!
    @IBOutlet weak var mapBtn: UIButton!
    @IBOutlet weak var searchTxtField: UITextField!
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var tableView: UITableView!
   
    let locationManager = CLLocationManager()
    var roqats: RoqatData?
    var mapSearchRoqats: RoqatData?
    var roqatsSearch: RoqatData?
    var loadPins = true
    var refreshControl: UIRefreshControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(MainViewController.refresh), for: UIControlEvents.valueChanged)
        tableView.addSubview(refreshControl)
        
        self.hideKeyboard()
        
        listBtn.layer.cornerRadius = 13
        if #available(iOS 11.0, *) {
            listBtn.layer.maskedCorners = [.layerMinXMaxYCorner,.layerMinXMinYCorner]
        } else {
            listBtn.roundCorners([.topLeft, .bottomLeft], radius: 13)
        }
        mapBtn.layer.cornerRadius = 13
        if #available(iOS 11.0, *) {
            mapBtn.layer.maskedCorners = [.layerMaxXMaxYCorner,.layerMaxXMinYCorner]
        } else {
            // Fallback on earlier versions
            mapBtn.roundCorners([.topLeft, .bottomLeft], radius: 13)
        }
        
        mapView.delegate = self
        
        // Ask for Authorisation from the User.
        self.locationManager.requestAlwaysAuthorization()
        
        // For use in foreground
        self.locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.distanceFilter = 20
            locationManager.startUpdatingLocation()
        }
        
        mapView.showsUserLocation = true
        centerMapOnLocation(location: CLLocationCoordinate2D(latitude: 24.788329683279827, longitude: 46.62597695312502))
        getRoqats(search:"")
        getRoqatsNoLocation(search:"")
        
        tableView.register(UINib(nibName: "RaqiCell", bundle: nil), forCellReuseIdentifier: "RaqiCell")
        
    }
    
    @objc func refresh(sender:AnyObject) {
        getRoqatsNoLocation(search:self.searchTxtField.text!)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.tabBarController?.tabBar.isHidden = false
    }
    
    static let dataDownloadCompleted = Notification.Name(
        rawValue: "backtolist")
    static let backFromPubName = Notification.Name(
        rawValue: "backFromPub")
    
    override func viewWillAppear(_ animated: Bool) {
        self.tabBarController?.tabBar.isHidden = false
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let locValue: CLLocationCoordinate2D = manager.location?.coordinate else { return }
        print("locations = \(locValue.latitude) \(locValue.longitude)")
        centerMapOnLocation(location: locValue)
    }
    
    let regionRadius: CLLocationDistance = 15000000
    func centerMapOnLocation(location: CLLocationCoordinate2D) {
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location,
                                                                  regionRadius, regionRadius)
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
    let regionRadiusClose: CLLocationDistance = 150000
    func centerMapOnLocationClose(location: CLLocationCoordinate2D) {
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location,
                                                                  regionRadiusClose, regionRadiusClose)
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
    @IBAction func mapPressed(_ sender: Any) {
        mapBtn.backgroundColor = UIColor.white
        mapBtn.setTitleColor(UIColor.init(red: 40/255, green: 120/255, blue: 173/255, alpha: 1.0), for: .normal)
        
        listBtn.backgroundColor = UIColor.init(red: 40/255, green: 120/255, blue: 173/255, alpha: 0)
        listBtn.setTitleColor(UIColor.white, for: .normal)
        tableView.isHidden = true
        searchTxtField.resignFirstResponder()
    }
    
    @IBAction func listPressed(_ sender: Any) {
        listBtn.backgroundColor = UIColor.white
        listBtn.setTitleColor(UIColor.init(red: 40/255, green: 120/255, blue: 173/255, alpha: 1.0), for: .normal)
        
        mapBtn.backgroundColor = UIColor.init(red: 40/255, green: 120/255, blue: 173/255, alpha: 0)
        mapBtn.setTitleColor(UIColor.white, for: .normal)
        tableView.isHidden = false
        searchTxtField.resignFirstResponder()
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func getRoqats(search: String)
    {
        activityIndicator.startAnimating()
        let citiesURL = URL(string:Constants.roqatsUrl+"&search=\(search)")!
        print(citiesURL)
        URLSession.shared.dataTask(with: citiesURL) { data, urlResponse, error in
            guard let data = data else { return }
            do {
                let decoder = JSONDecoder()
                //print("sdfsdf",data)
                
                self.roqats = try decoder.decode(RoqatData.self, from: data)
                
                //self.roqatsSearch = try decoder.decode(RoqatData.self, from: data)
                //print("sdfsdf",self.roqats?.resultObject!.count ?? "wewe")
                DispatchQueue.main.async {

                    // Remove previous
                    let allAnnotations = self.mapView.annotations
                    self.mapView.removeAnnotations(allAnnotations)
                    
                    var i : Int = 0
                    for r in (self.roqats?.resultObject!)!
                    {
                        let annotation = MyPointAnnotation()
                        annotation.index = i
                        annotation.coordinate = CLLocationCoordinate2D(latitude: Double(r.latitude!)!, longitude: Double(r.longitude!)!)
                        self.mapView.addAnnotation(annotation)
                        i = i + 1
                    }
                    self.mapView.showAnnotations(self.mapView.annotations, animated: true)
                    
                    if(search.count > 0){
                    if((self.roqats?.resultObject!.count)! < 1){
                    
                        let alert = UIAlertController(title: "تنبيه", message: "لا يوجد رقاة بهذا الإسم ,شكرا.", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "حسنا", style: .`default`, handler: { _ in
                            alert.dismiss(animated: true)
                            print("Noooo")
                        }))
                        self.present(alert, animated: true, completion: nil)
                    
                    }
                    //print(self.roqats?.)
                    }}
            } catch {
                print("erroooooor",error)
            }
            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()}
            }.resume()
    }
    
    func getRoqatsNoLocation(search: String)
    {
        activityIndicator.startAnimating()
        let citiesURL = URL(string:Constants.roqatsNoLocationUrl+"&search=\(search)")!
        print(citiesURL)
        URLSession.shared.dataTask(with: citiesURL) { data, urlResponse, error in
            guard let data = data else { return }
            do {
                let decoder = JSONDecoder()
                //print("sdfsdf",data)
                self.roqatsSearch = try decoder.decode(RoqatData.self, from: data)
                //print("sdfsdf",self.roqats?.resultObject!.count ?? "wewe")
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            } catch {
                print("erroooooor",error)
            }
            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()
                self.refreshControl.endRefreshing()
            }
            }.resume()
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            let annotationViewUser = MKAnnotationView(annotation: annotation, reuseIdentifier: "user")
            annotationViewUser.image = UIImage(named: "map2")
            return annotationViewUser
        }
        var annotationView: MKAnnotationView? = mapView.dequeueReusableAnnotationView(withIdentifier: "String")
        if annotationView == nil {
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: "String")
            let myAnnotation = annotation as! MyPointAnnotation
            annotationView?.tag = myAnnotation.index!
        }
        else  {
            annotationView?.annotation = annotation
            let myAnnotation = annotation as! MyPointAnnotation
            annotationView?.tag = myAnnotation.index!
        }
        
        let customView = Bundle.main.loadNibNamed("CustomXibCallout", owner: nil, options: nil)![0] as! CustomXibCallout;
        customView.delegate = self
        
        customView.frame = CGRect(x: 0, y: 0, width: customView.frame.width, height: customView.frame.height)
        customView.tag = (annotationView?.tag)!
        print((annotationView?.tag)!)
        print((self.roqats?.resultObject!.count)!)
        print("yyyyyyyyy",(annotationView?.tag)!)
        let raqi = self.roqats?.resultObject![(annotationView?.tag)!]
        // create func to set raqi data
        customView.setRaqiData(raqi: raqi!)
        
        annotationView?.frame = customView.frame
        annotationView?.addSubview(customView)
        
        return annotationView
    }
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if view.annotation!.isKind(of: MKUserLocation.self){
            return
        }
        navigateDetailsMap(index:view.tag)
        
    }
    
    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView)
    {

    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if self.roqatsSearch != nil {
            return (self.roqatsSearch?.resultObject!.count)!
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell:RaqiCell = self.tableView.dequeueReusableCell(withIdentifier: "RaqiCell" , for: indexPath) as! RaqiCell
        let raqi : Roqat = (self.roqatsSearch?.resultObject![indexPath.row])!
        cell.setRaqi(raqi: raqi)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 75
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView .deselectRow(at: indexPath, animated: true)
        
        navigateDetails(index:indexPath.row)
        
    }
    
    @IBAction func infoPressed(_ sender: Any) {

            let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let newViewController = storyBoard.instantiateViewController(withIdentifier: "contactViewController") as! ContactViewController
            self.navigationController?.pushViewController(newViewController, animated: true)

        searchTxtField.resignFirstResponder()
    }
    
    @IBAction func pubPressed(_ sender: Any) {
        searchTxtField.resignFirstResponder()

            let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let newViewController = storyBoard.instantiateViewController(withIdentifier: "pubViewController") as! PubViewController
            self.navigationController?.pushViewController(newViewController, animated: true)
        
    }
    
    func navigateDetails(index : Int)
    {
        let idUser = UserDefaults.standard.integer(forKey: "idUser")
        if(idUser == 0){
            let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let newViewController = storyBoard.instantiateViewController(withIdentifier: "loginViewController") as! LoginViewController
            self.navigationController?.pushViewController(newViewController, animated: true)
            self.tabBarController?.tabBar.isHidden = true
        }else{
            let raqi = self.roqatsSearch?.resultObject![index]
            let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let newViewController = storyBoard.instantiateViewController(withIdentifier: "detailsRaqiViewController") as! DetailsRaqiViewController
            newViewController.raqi = raqi
            self.navigationController?.pushViewController(newViewController, animated: true)
        }
    }
    
    func navigateDetailsMap(index : Int)
    {
        searchTxtField.resignFirstResponder()
        let idUser = UserDefaults.standard.integer(forKey: "idUser")
        if(idUser == 0){
            let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let newViewController = storyBoard.instantiateViewController(withIdentifier: "loginViewController") as! LoginViewController
            self.navigationController?.pushViewController(newViewController, animated: true)
            self.tabBarController?.tabBar.isHidden = true
        }else{
            let raqi = self.roqats?.resultObject![index]
            let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let newViewController = storyBoard.instantiateViewController(withIdentifier: "detailsRaqiViewController") as! DetailsRaqiViewController
            newViewController.raqi = raqi
            self.navigationController?.pushViewController(newViewController, animated: true)
        }
    }
    
    func searchRoqats(val : String)
    {
        activityIndicator.startAnimating()
        let strUrl = Constants.roqatsUrl+"&search=\(val)"
        let citiesURL = URL(string:strUrl)!
        URLSession.shared.dataTask(with: citiesURL) { data, urlResponse, error in
            guard let data = data else { return }
            do {
                let decoder = JSONDecoder()
                //print("sdfsdf",data)
                self.roqatsSearch = try decoder.decode(RoqatData.self, from: data)
                //print("sdfsdf",self.roqats?.resultObject!.count ?? "wewe")
                DispatchQueue.main.async {
                    if((self.roqatsSearch?.resultObject!.count)! > 0){
                    self.tableView.reloadData()
                    
                    let anno : Roqat = (self.roqatsSearch?.resultObject?.last)!
                    self.centerMapOnLocationClose(location: CLLocationCoordinate2D(latitude: Double(anno.latitude!)!, longitude: Double(anno.longitude!)!))
                    } else {
                        let alert = UIAlertController(title: "تنبيه", message: "لا يوجد رقاة بهذا الإسم ,شكرا.", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "حسنا", style: .`default`, handler: { _ in
                            alert.dismiss(animated: true)
                            print("Noooo")
                        }))
                        self.present(alert, animated: true, completion: nil)
                    }
                }
            } catch {
                print("erroooooor",error)
            }
            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()}
            }.resume()
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        getRoqats(search:textField.text!)
        getRoqatsNoLocation(search:textField.text!)
        
        return true
    }
    class MyPointAnnotation : MKPointAnnotation {
        var index: Int?
    }
    
}

extension UIView {
    func roundCorners(_ corners:UIRectCorner, radius: CGFloat) {
        let path = UIBezierPath(roundedRect: self.bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        self.layer.mask = mask
    }
}
