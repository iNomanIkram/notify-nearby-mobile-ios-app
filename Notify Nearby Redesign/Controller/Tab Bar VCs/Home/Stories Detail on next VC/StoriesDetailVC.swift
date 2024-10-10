//
//  StoriesDetailVC.swift
//  Notify Nearby Redesign
//
//  Created by Noman Ikram on 09/09/2018.
//  Copyright © 2018 nomanikram. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage
import SwiftyJSON
import SVProgressHUD
import CoreLocation

class StoriesDetailVC: UIViewController ,UICollectionViewDelegate,UICollectionViewDataSource , UINavigationControllerDelegate , UIImagePickerControllerDelegate,CLLocationManagerDelegate {
    
    var locationManager = CLLocationManager()
  
    @IBOutlet weak var hidden_latitude: UILabel!
    @IBOutlet weak var hidden_longitude: UILabel!
    @IBOutlet weak var hidden_storyAuthorKey: UILabel!
    
    
    var Previouskey :String? // Story/Ad Key which is selected on any screen
    var event:Event?
    var interestArray = [String]()
    
    var commonInt:[String]?
    
    let database = Database.database().reference()
    let auth = Auth.auth()
    let uid = Auth.auth().currentUser?.uid
    
    @IBOutlet weak var event_title: UILabel!
    
    @IBOutlet weak var event_description: UITextView!
    
    @IBOutlet weak var event_image: UIImageView!
    @IBOutlet weak var deleteButton: TransparentButton!
    @IBOutlet weak var editButton: BlackBorderSmallButton!
    
    @IBOutlet weak var collectionview: UICollectionView!
    
    
    var contact:String?
    
    
    @IBOutlet weak var phoneButton: UIButton!
    @IBOutlet weak var messageButton: UIButton!
    
    
    // when phone button is pressed then it would call
    @IBAction func phoneButtonPressed(_ sender: Any) {
        print(contact)
        let url = URL(string: "telprompt://\(contact!)") // default pattern given by apple to dialup screen
        UIApplication.shared.open(url!, options: [:], completionHandler: nil)
        

    
    }
    
    // when message button is pressed then it will take to the message screen
    @IBAction func messageButtonPressed(_ sender: Any) {
        print(contact)
        let url = URL(string: "sms://\(contact!)") // default pattern given by apple to open message application
        UIApplication.shared.open(url!, options: [:], completionHandler: nil)
    }
    
    
    
    /* Addional Views */
    @IBOutlet var blackBgView: UIView!
    @IBOutlet var editStoryView: UIView!
    
    @IBOutlet weak var editStoryView_imageview: UIImageView!
    @IBOutlet weak var editStoryView_title: UITextField!
    @IBOutlet weak var editStoryView_interest: UITextField!
    @IBOutlet weak var editStoryView_description: UITextView!
    
    
    
    @IBAction func changePhoto(_ sender: Any) {
        let image = UIImagePickerController()
        image.delegate = self
        image.sourceType = UIImagePickerControllerSourceType.photoLibrary
        self.present(image, animated: true, completion: nil)
        
    }
    
    
    @IBAction func updateButtonPressed(_ sender: Any) {
        SVProgressHUD.show()
       
        let storageRef = Storage.storage().reference()
        
        let userRef = database.child("Users").child(uid!).child("stories").child(Previouskey!).setValue(Previouskey)
        let tempImgRef = storageRef.child("images/\(Previouskey).jpg")
        
        // creating metafile which contains information about the image which we will save in the database
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        
        // it place the image in the storage on firebase
        tempImgRef.putData(UIImageJPEGRepresentation(editStoryView_imageview.image!, 0)!, metadata: metadata) { (data, error) in
            // if image is uploaded successfully and you can say that there is no error
            if error == nil {
                
                tempImgRef.downloadURL(completion: { (url, error) in
     
                    self.database.child("stories").child(self.Previouskey!).child("description").setValue(self.editStoryView_description.text)
                    self.database.child("stories").child(self.Previouskey!).child("title").setValue(self.editStoryView_title.text)
        
                    //FIXME: Changes made lowercased()
                    self.database.child("stories").child(self.self.Previouskey!).child("interest").setValue(self.editStoryView_interest.text?.lowercased())
        
                    self.database.child("stories").child(self.Previouskey!).child("image").setValue("\(url!)")
            
                    SVProgressHUD.dismiss()
                    SVProgressHUD.showSuccess(withStatus: "Updated")
                    // Intiantiate Main Screen
                    let vc = self.storyboard?.instantiateViewController(withIdentifier: "SWRevealViewController") as! SWRevealViewController
                    self.present(vc, animated: true, completion: nil)
                    
//                        self.dismiss(animated: true, completion: nil)
                })
                
            }else{
                SVProgressHUD.dismiss()
                SVProgressHUD.showError(withStatus: "Failed to Update")
                print("Image Upload Failure")
            }
        }
                
//        database.child("stories").child(Previouskey).child("image").setValue(<#T##value: Any?##Any?#>)
        
    }
    
    
//    // functions for picking image from CameraRoll
//    @IBAction func uploadImage(_ sender: Any) {
//        let image = UIImagePickerController()
//        image.delegate = self
//        image.sourceType = UIImagePickerControllerSourceType.photoLibrary
//        self.present(image, animated: true, completion: nil)
//    }
    
    // choose image from cameraRoll
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        let theInfo:NSDictionary = info as NSDictionary
        let img:UIImage = theInfo.object(forKey: UIImagePickerControllerOriginalImage) as! UIImage
        editStoryView_imageview.image = img
        self.dismiss(animated: true, completion: nil)
    }
    
    // when we touch outside the textfield then keyboard will disappear
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    // when we will touch on return button on key it will hide the keyboard
    func textFieldShouldReturn(_ textField: UITextField) -> Bool{
        textField.resignFirstResponder()
        return true
    }
    
    @IBAction func cancelButtonPressed(_ sender: Any) {
        
        UIView.animate(withDuration: 1) {
            self.blackBgView.alpha = 0
            
            for v in self.view.subviews{
                if v == self.editStoryView{
                    v.removeFromSuperview()
                }
            }
        }
        
    }
    
    
    /* Additional View Ended */
    
    //    @IBOutlet weak var mapview: MKMapView!
    
    
    
    
    // Collection View to Display the interests related to the story/ads
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
      
//        print("Interest Count: \(interestArray?.count)")
        return interestArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionview.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! interestStoryDetailCVC
        cell.interest.text = interestArray[indexPath.row]
        return cell
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
            return CGSize(width: collectionview.frame.size.width / 4, height: collectionview.frame.size.height - 8)
     
    }
    
    
    // Alert for Report button
    @IBAction func reportButtonPressed(_ sender: Any) {
        print("Report Button Pressed")
        
        let actionsheet = UIAlertController(title: "Feedback", message: "Help us understand what's happening", preferredStyle: .actionSheet)
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        let fakeInformation = UIAlertAction(title: "Fake Information", style: .default) { (action) in
            self.reportType(reason: "Fake Information")
//            self.alertTicketMessage(ticketno: "Fake Information")
        }
        
        let pretendingToBeSomeoneElse = UIAlertAction(title: "Pretending to be Someone", style: .default) { (action) in
            self.reportType(reason: "Pretending to be Someone")
//            self.alertTicketMessage(ticketno: "Pretending to be Someone")
        }
        
        let unethicalContent = UIAlertAction(title: "Unethical Content", style: .default) { (action) in
           
            self.reportType(reason: "Unethical Content")
//            self.alertTicketMessage(ticketno: "Unethical Content")
        }
        
        let fakeAccount = UIAlertAction(title: "Fake Account", style: .default) { (action) in
            self.reportType(reason: "Fake Account")
//            self.alertTicketMessage(ticketno: "Fake Account")
        }
        
        let offensiveBehaviour = UIAlertAction(title: "Offensive Behaviour", style: .default) { (action) in
            self.reportType(reason: "Offensive Behaviour")
//            self.alertTicketMessage(ticketno: "Offensive Behaviour")
            
        }
        
        actionsheet.addAction(fakeInformation)
        actionsheet.addAction(fakeAccount)
        actionsheet.addAction(pretendingToBeSomeoneElse)
        actionsheet.addAction(unethicalContent)
        actionsheet.addAction(offensiveBehaviour)
        actionsheet.addAction(cancel)
        
//        reportType(reason: "")
        
        present(actionsheet, animated: true, completion: nil)
        
    }
    
    // alertaction
    func reportType(reason:String)  {

        var ticketnumber = Int(arc4random_uniform(99999))
        
            let data = ["reason":"\(reason)",
                "reportedbyuserid":"\(self.uid!)",
                "reportedid":"\((self.event?.event_author_uid)!)",
                "reportedusername":"\((self.event?.event_author)!)",
                "ticket":"\(ticketnumber)"]
            
        self.database.child("Tickets").childByAutoId().setValue(data) { (error, ref) in
            if error == nil{
                self.alertTicketMessage(ticketno: "\(ticketnumber)")
            }
        }
    
    }
    
    func alertTicketMessage(ticketno:String){
        let alertcontroller = UIAlertController(title: "Ticket Number", message: "Your Ticket Number: \(ticketno)", preferredStyle: .alert)
         alertcontroller.addAction(UIAlertAction(title: "Okay", style: .cancel, handler: nil))
        present(alertcontroller, animated: true, completion: nil)
    }
    
    @IBAction func acceptButtonPressed(_ sender: Any) {
         print("Accept Button Pressed")
        
        
        
//        let view = sender.superview as! StoryCalloutView
//        let storyKey = view.sKey.text!
        //        print("Story Key: \(storyKey)")
        
        let acceptedRef =  database.child("stories").child(Previouskey!).child("accepted")
        
        
        acceptedRef.observeSingleEvent(of: DataEventType.value) { (snapshot) in
            var count = snapshot.childrenCount
            //            print(count)
            
            if count == 0 {
                self.database.child("stories").child(self.Previouskey!).child("accepted").childByAutoId().setValue(self.uid)
                
                self.database.child("Users").child(self.uid!).child("accepted").childByAutoId().setValue(self.Previouskey)
                
                count = snapshot.childrenCount
                SVProgressHUD.showSuccess(withStatus: "Accepted")
//                view.noOfAccept.text = "\(count+1)"
                self.database.child("stories").child(self.Previouskey!).child("acceptedNumber").setValue("\(count+1)")
                self.notifyAcceptedStory()
            }else{
                
                
                
                
                for id in snapshot.children{
                    if ((id as! DataSnapshot).hasChild(self.uid!)){
                        
                        
                        self.database.child("stories").child(self.Previouskey!).child("accepted").childByAutoId().setValue(self.uid)
                        
                        self.database.child("Users").child(self.uid!).child("accepted").childByAutoId().setValue(self.Previouskey)
                        
                        count = snapshot.childrenCount
                        
//                        view.noOfAccept.text = "\(count+1)"
                        self.database.child("stories").child(self.Previouskey!).child("acceptedNumber").setValue("\(count+1)")
                        
                        SVProgressHUD.showSuccess(withStatus: "Accepted")
                        self.notifyAcceptedStory()
                        //                        print("Extered")
                    }else{
                        //                        print("Already exists")
                        
                        //                        count = snapshot.childrenCount
                        //                        self.databaseRef.child("stories").child(storyKey).child("acceptedNumber").setValue(count+1)
                        SVProgressHUD.showError(withStatus: "Already Accepted")
                        return
                    }
                }
            }//else ending
            
            //    count = snapshot.childrenCount
            //   self.databaseRef.child("stories").child(storyKey).child("acceptedNumber").setValue(count)
        }
        
        
    }
    
    @IBAction func rejectButtonPressed(_ sender: Any) {
         print("Reject Button Pressed")
        
        
//        let view = sender.superview as! StoryCalloutView
//        let storyKey = view.sKey.text!
        //        print("Story Key: \(storyKey)")
        
        let deniedRef =  database.child("stories").child(Previouskey!).child("denied")
        
        
        deniedRef.observeSingleEvent(of: DataEventType.value) { (snapshot) in
            var count = snapshot.childrenCount
            //            print(count)
            
            if count == 0 {
                self.database.child("stories").child(self.Previouskey!).child("denied").childByAutoId().setValue(self.uid)
                
                self.database.child("Users").child(self.uid!).child("denied").childByAutoId().setValue(self.Previouskey)
                
                count = snapshot.childrenCount
                SVProgressHUD.showSuccess(withStatus: "Denied")
//                view.noOfDeny.text = "\(count+1)"
                self.database.child("stories").child(self.Previouskey!).child("deniedNumber").setValue("\(count+1)")
               self.notifyRejectedStory()
            }else{
                
                
                
                
                for id in snapshot.children{
                    if ((id as! DataSnapshot).hasChild(self.uid!)){
                        
                        self.database.child("stories").child(self.Previouskey!).child("denied").childByAutoId().setValue(self.uid)
                        
                        self.database.child("Users").child(self.uid!).child("denied").childByAutoId().setValue(self.Previouskey!)
                        
                        
                        count = snapshot.childrenCount
                        
//                        view.noOfDeny.text = "\(count+1)"
                        self.database.child("stories").child(self.Previouskey!).child("deniedNumber").setValue("\(count+1)")
                        
                        SVProgressHUD.showSuccess(withStatus: "Denied")
                        self.notifyRejectedStory()
                        
                        //                        print("Extered")
                    }else{
                        //                        print("Already exists")
                        
                        //                        count = snapshot.childrenCount
                        //                        self.databaseRef.child("stories").child(storyKey).child("deniedNumber").setValue(count+1)
                        SVProgressHUD.showError(withStatus: "Already Denied")
                        return
                    }
                }
            }//else ending
            
            //   count = snapshot.childrenCount
            //self.databaseRef.child("stories").child(storyKey).child("deniedNumber").setValue(count+1)
        }
        
    }
    
    @IBAction func deleteButtonPressed(_ sender: Any) {
        SVProgressHUD.show()
         print("Delete Button Pressed")
        
        database.child("stories").child(Previouskey!).removeValue()
        
        database.child("Users").child(uid!).child("stories").observe(.value) { (snapshot) in
            for snap in snapshot.children{
                // if the selected story is present/matches with the story present in the firebase database then it would delete that story
                if (snap as! AnyObject).value == self.Previouskey{
                    (snap as! AnyObject).ref.removeValue()
                print("Deleted Successfully")
                   
                    SVProgressHUD.dismiss()
                    SVProgressHUD.showSuccess(withStatus: "Deleted Successfully")
                    
                    // Intiantiate Main Screen
                    let vc = self.storyboard?.instantiateViewController(withIdentifier: "SWRevealViewController") as! SWRevealViewController
                    self.present(vc, animated: true, completion: nil)
                    
                }else{
//                  SVProgressHUD.showError(withStatus: "Failed to Delete")
                    print("Failed to Delete")
                }
            }
            
        }
        
    }

    
    @IBAction func favouriteButtonPressed(_ sender: Any) {
        print("Favourite Button Pressed")
        
        joint()
        
//        let view = sender.superview as! StoryCalloutView
//        let storyKey = view.sKey.text!
        //        print("Story Key: \(storyKey)")
        
        let favouriteRef =  database.child("stories").child(Previouskey!).child("favourite")
        
        
        favouriteRef.observeSingleEvent(of: DataEventType.value) { (snapshot) in
            var count = snapshot.childrenCount
            //            print(count)
            
            
            
            
            if count == 0 {
                self.database.child("stories").child(self.Previouskey!).child("favourite").childByAutoId().setValue(self.uid)
                
                self.database.child("Users").child(self.uid!).child("favourite").childByAutoId().setValue(self.Previouskey)
                
                count = snapshot.childrenCount
                SVProgressHUD.showSuccess(withStatus: "Favourite")
//                view.noOfFavourite.text = "\(count+1)"
                self.database.child("stories").child(self.Previouskey!).child("favouriteNumber").setValue("\(count+1)")
                
                self.notifyFavouriteStory()
            }else{
                
                for id in snapshot.children{
                    
                    
                    
                    if ((id as! DataSnapshot).hasChild(self.uid!)){
                        
                        self.database.child("stories").child(self.Previouskey!).child("favourite").childByAutoId().setValue(self.uid)
                        
                        self.database.child("Users").child(self.uid!).child("favourite").childByAutoId().setValue(self.Previouskey)
                        
                        
                        count = snapshot.childrenCount
                        
//                        view.noOfFavourite.text = "\(count+1)"
                        self.database.child("stories").child(self.Previouskey!).child("favouriteNumber").setValue("\(count+1)")
                        SVProgressHUD.showSuccess(withStatus: "Favourite")
                        self.notifyFavouriteStory()
                        //                        print("Extered")
                    }else{
                        //                        print("Already exists")
                        
                        //                        count = snapshot.childrenCount
                        //                        self.databaseRef.child("stories").child(storyKey).child("favouriteNumber").setValue(count+1)
                        SVProgressHUD.showError(withStatus: "Already Favourite")
                        return
                    }
                }
            }//else ending
            
        }
    }
    
    
    // it fetches the all interests of the story/ads and story it in the separate in database with its mentioned start time and end time
    func joint() {
        let database = Database.database().reference().child("JointInterest").child((Auth.auth().currentUser?.uid)!)
        print(event?.event_interests)
        var arr = stringToArray(string: (event?.event_interests)!)
        
        for i in arr{
            let data = ["interest":"\(i)",
                        "startTime":"\(AppDelegate.totalSeconds!)",
                        "endTime":"\(AppDelegate.totalSeconds! + 86400)"]
            database.childByAutoId().setValue(data)
        }
//        database.childByAutoId().
        
    }
    
    /* These Notify Functions are there to give the notification of our action to the author of story/ad */
    
    func notifyAcceptedStory(){
        // hidden_storyAuthorKey refers to the author of story
        let uid = auth.currentUser?.uid
        
        let database = Database.database().reference().child("Notifications").child(hidden_storyAuthorKey.text!).childByAutoId()
        let data = ["sid":Previouskey!, // Previous key Refer to the story id
                    "string":"has confirmed your story",
                    "type":"confirmed",
                    "userid":"\(uid!)"] // auth refers to firebase logged in user
        database.setValue(data)
    }
    
    func notifyRejectedStory(){
        // hidden_storyAuthorKey refers to the author of story
        let uid = auth.currentUser?.uid
        
        
        let database = Database.database().reference().child("Notifications").child(hidden_storyAuthorKey.text!).childByAutoId()
        let data = ["sid":Previouskey!, // Previous key Refer to the story id
            "string":"has denied your story",
            "type":"confirmed",
            "userid": "\(uid!)"] // auth refers to firebase logged in user
        database.setValue(data)
    }
    
    func notifyFavouriteStory(){
        // hidden_storyAuthorKey refers to the author of story
        let uid = auth.currentUser?.uid
        
        let database = Database.database().reference().child("Notifications").child(hidden_storyAuthorKey.text!).childByAutoId()
        let data = ["sid":Previouskey!, // Previous key Refer to the story id
            "string":"has favorited your story",
            "type":"confirmed",
            "userid":"\(uid!)"] // auth refers to firebase logged in user
        database.setValue(data)
    }
    
    
    @IBAction func editButtonPressed(_ sender: Any) {
         print("Edit Button Pressed")
        
//        blackBgView.alpha = 0
        blackBgView.frame.size.height = view.frame.height
        blackBgView.frame.size.width = view.frame.width
        editStoryView.center = view.center
        editStoryView.frame.origin.y = 16
         view.addSubview(blackBgView)
        
      
        
        UIView.animate(withDuration: 1) {
            self.blackBgView.alpha = 0.4
            self.view.addSubview(self.editStoryView)
        }
        
    }
    
    
    // not being used
    func fetchJoint() {
        let database = Database.database().reference().child("JointInterest").child((Auth.auth().currentUser?.uid)!)
        database.observe(.value) { (snapshot) in
            print("****fetchJoint()****")
            
            for i in snapshot.children{
                let joint = JointInterest(json: JSON((i as! DataSnapshot).value), id: (i as! DataSnapshot).key)
                print(joint.id)
                print(joint.interest)
                print(joint.startTime)
                print(joint.endTime)
                if Int(joint.endTime!)! >= AppDelegate.totalSeconds!{
                    print("time ended")
                }
            }
            
            
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        fetchJoint()
        
        // Do any additional setup after loading the view.
        print("\(Previouskey)")
        
        
    
        // Go through all events
        for event in HomeTVC.eventArray{
            
            // finding the one story/ads which was selected from any screen among all events
            if event.event_key == Previouskey {
                
                print(event.event_key)
                print(Previouskey)
                
                self.event = event
                interestArray = stringToArray(string: event.event_interests!)
//               let commonset =  commonInterest(firstSet: interestArray!, secondSet: MyInterestVC.interest)
//               commonInt =  commonInterestToStringArrayList(common: commonset)
                //                print("\(event.event_title)")
//                let url = URL(
                
                event_title.text = event.event_title
                event_image.sd_setImage(with: URL(string:event.event_image!), completed: nil)
                
                
                editStoryView_title.text = event.event_title
                editStoryView_description.text = event.event_description
                event_description.text = event.event_description
                editStoryView_interest.text = event.event_interests
                editStoryView_imageview.sd_setImage(with: URL(string: event.event_image!), completed: nil)
                
                hidden_latitude.text = "\(event.event_latitude!)"
                hidden_longitude.text = "\(event.event_longitude!)"
                
                hidden_storyAuthorKey.text = event.event_author_uid
                
                contact = event.event_contact
                
                
                if event.event_author_uid == Auth.auth().currentUser?.uid{
                    deleteButton.isHidden = false
                    editButton.isHidden = false
                }else{
                    deleteButton.isHidden = true
                    editButton.isHidden = true
                }
                
                if event.event_type == "advertisement" {
                    phoneButton.isHidden = false
                    messageButton.isHidden = false
                }else if event.event_type == "story" || contact ==  ""{
                    phoneButton.isHidden = true
                    messageButton.isHidden = true
                }
                
                break
            }
        }
//        collectionview.reloadData()
        
//        mapview_height = mapview.frame.size.height
//        mapview_width = mapview.frame.size.width
//        mapview_x = mapview.frame.origin.x
//        mapview_y = mapview.frame.origin.y
        
        
    }

    override func viewDidAppear(_ animated: Bool) {
        print("*************StoryDetailVC**************")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func backButton(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    

    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    
    
//    MARK: - GETTING common Interest

    //1: converting string to string array
    func stringToArray(string:String)->[String]{
        var string = string
        var removeWhiteSpcSTR = string.replacingOccurrences(of: " ", with: "")
        var strArray : [String] = removeWhiteSpcSTR.components(separatedBy: ",")
        return strArray
    }

    //2: finding common interest from two string arrays
    func commonInterest(firstSet:[String],secondSet:[String]) -> Set<String>{

        var userInterest = firstSet
        let userSet:Set = Set(userInterest.map { $0 })

        //    var str = "Hello, playground, sad, a,as "
        //    var removeWhiteSpcSTR = str.replacingOccurrences(of: " ", with: "")
        //    var strArray : [String] = removeWhiteSpcSTR.components(separatedBy: ",")

        let strSet:Set = Set(secondSet.map { $0 })
        //    print(strSet)

        let common = userSet.intersection(strSet)
        //        print(common)
        return common
    }

    //3: converting common set element to string form for printing
    func commonInterestToString(common : Set<String>) -> String {
        var stringers = ""
        for val in common {
            stringers = "\(stringers) \(val)"
        }
        return stringers
    }

    //4: converting common set element to arraylistform for printing
    func commonInterestToStringArrayList(common : Set<String>) -> [String] {
        var str = [String]()

//        var stringers = ""
        for val in common {
            str.append(val)

        }
        return str
    }
    
    //TODO: To calculate the distance
    func calculateDistance(mainCoordinate: CLLocation,coordinate: CLLocation) -> Double{
        
        let distance = mainCoordinate.distance(from: coordinate)
        //        print("Calculate Distance: \(distance)")
        
        return distance
    }
    
    
    
    //TODO: Direction Related Functionality
    
    @IBAction func showDirection(_ sender: Any) {
        openMapForPlace()
    }
    
    
    //Alas: Apple Map do not show direction in Pakistan
    func openMapForPlace() {
        
        
        guard let userLocation = locationManager.location else {return}
        
        print(userLocation.coordinate.latitude)
        print(userLocation.coordinate.longitude)
        
        print(hidden_latitude.text!)
        print(hidden_longitude.text!)
//        print(userLocation.coordinate.latitude)
        
        UIApplication.shared.openURL(URL(string:
            "comgooglemaps://?saddr=\(userLocation.coordinate.latitude),\(userLocation.coordinate.longitude)&daddr=\(hidden_latitude.text!),\(hidden_longitude.text!)&directionsmode=driving")!)
        
        
        
//        let latitude: CLLocationDegrees = 33.7153
//        let longitude: CLLocationDegrees = 73.1020
//
//        let regionDistance:CLLocationDistance = 10000
//        let coordinates = CLLocationCoordinate2DMake(latitude, longitude)
//        let regionSpan = MKCoordinateRegionMakeWithDistance(coordinates, regionDistance, regionDistance)
//        let options = [
//            MKLaunchOptionsMapCenterKey: NSValue(mkCoordinate: regionSpan.center),
//            MKLaunchOptionsMapSpanKey: NSValue(mkCoordinateSpan: regionSpan.span)
//        ]
//        let placemark = MKPlacemark(coordinate: coordinates, addressDictionary: nil)
//        let mapItem = MKMapItem(placemark: placemark)
//        mapItem.name = "Place Name"
//        mapItem.openInMaps(launchOptions: options)
        
        
    }

}
