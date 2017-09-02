import Foundation

// NOTE: Uncommment following two lines for use in a Playground
 import PlaygroundSupport
 PlaygroundPage.current.needsIndefiniteExecution = true

URLCache.shared = URLCache(memoryCapacity: 0, diskCapacity: 0, diskPath: nil)


func GetGalleryIDs(GetGalleryIDsCallBack:@escaping (String) -> ()) {
    let url = URL(string: "https://api.kairos.com/gallery/view")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    request.addValue("66261a1d", forHTTPHeaderField: "app_id")
    request.addValue("11da5256b834011f91378a81202a1393", forHTTPHeaderField: "app_key")
    
    request.httpBody = "{\n  \"gallery_name\": \"MyGallery\"\n}".data(using: .utf8)
    
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        //if let response = response, let data = data {
        if let data = data {
            GetGalleryIDsCallBack(String(data: data, encoding: .utf8)!)
        } else {
            GetGalleryIDsCallBack( "You got an error")
        }
    }
    
    task.resume()
}


func PostNewFace(ImageString: String, NameString: String, GalleryString: String, PostNewFaceCallBack:@escaping (String) -> ()){

    let url = URL(string: "https://api.kairos.com/enroll")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    request.addValue("66261a1d", forHTTPHeaderField: "app_id")
    request.addValue("11da5256b834011f91378a81202a1393", forHTTPHeaderField: "app_key")
    
    request.httpBody = ("{\n  \"image\": \"" + ImageString + "\",\n  \"subject_id\": \"" + NameString + "\",\n  \"gallery_name\": \"" + GalleryString + "\"\n}").data(using: .utf8)
    
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        //if let response = response, let data = data {
        if let data = data {
            //PostNewFaceCallBack(response)
            PostNewFaceCallBack(String(data: data, encoding: .utf8)!)
        } else {
            PostNewFaceCallBack("You got an error")
        }
    }
    
    task.resume()
}

func VerifyFace(ImageString: String, NameString: String, GalleryString: String, VerifyFaceCallBack:@escaping (String) -> ()){
    let url = URL(string: "https://api.kairos.com/verify")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    request.addValue("66261a1d", forHTTPHeaderField: "app_id")
    request.addValue("11da5256b834011f91378a81202a1393", forHTTPHeaderField: "app_key")
    
    request.httpBody = ("{\n  \"image\": \"" + ImageString + "\",\n  \"gallery_name\": \"" + GalleryString + "\",\n  \"subject_id\": \"" + NameString + "\"\n}").data(using: .utf8)
    
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        //if let response = response, let data = data {
        if let data = data {
            //VerifyFaceCallBack(response)
            VerifyFaceCallBack(String(data: data, encoding: .utf8)!)
        } else {
            VerifyFaceCallBack("Youve got an error")
        }
    }
    
    task.resume()
}

func RecogniseFace(ImageString: String, GalleryString: String, RecogniseFaceCallBack:@escaping (String) -> ()){
    let url = URL(string: "https://api.kairos.com/recognize")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    request.addValue("66261a1d", forHTTPHeaderField: "app_id")
    request.addValue("11da5256b834011f91378a81202a1393", forHTTPHeaderField: "app_key")
    
    request.httpBody = ("{\n  \"image\": \"" + ImageString + "\",\n  \"gallery_name\": \"" + GalleryString + "\"\n}").data(using: .utf8)
    
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        //if let response = response, let data = data {
        if let data = data {
            //RecogniseFaceCallBack(response)
            RecogniseFaceCallBack(String(data: data, encoding: .utf8)!)
        } else {
            RecogniseFaceCallBack("Youve got an error")
        }
    }
    
    task.resume()
}

func RemoveID(NameString: String, GalleryString: String, RemoveIDCallBack:@escaping (String) -> ()){
    let url = URL(string: "https://api.kairos.com/gallery/remove_subject")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    request.addValue("66261a1d", forHTTPHeaderField: "app_id")
    request.addValue("11da5256b834011f91378a81202a1393", forHTTPHeaderField: "app_key")
    
    request.httpBody = ("{\n  \"gallery_name\": \"" + GalleryString + "\",\n  \"subject_id\": \"" + NameString + "\"\n}").data(using: .utf8)
    
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        //if let response = response, let data = data {
        if let data = data {
            //RemoveIDCallBack(response)
            RemoveIDCallBack(String(data: data, encoding: .utf8)!)
        } else {
            RemoveIDCallBack("Youve got an error")
        }
    }
    
    task.resume()
}



GetGalleryIDs() { success in
    print(success)
}


/*
PostNewFace(ImageString: "http://media.kairos.com/kairos-elizabeth.jpg", NameString: "Elizabeth1", GalleryString: "MyGallery"){success in
    print(success)
}
 */

/*
VerifyFace(ImageString: "http://media.kairos.com/kairos-elizabeth2.jpg", NameString: "Eliz2", GalleryString: "MyGallery"){success in
    print(success)
}
 */

/*
RecogniseFace(ImageString: "http://media.kairos.com/kairos-elizabeth2.jpg", GalleryString: "MyGallery"){success in
    print(success)
}
 */

/*
 RemoveID(NameString: "Simon1", GalleryString: "MyGallery"){success in
 print(success)
 }
 */




