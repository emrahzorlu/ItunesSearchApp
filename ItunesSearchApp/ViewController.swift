import UIKit

struct SearchResult {
    let artworkUrl100: String
    let collectionPrice: Double
    let collectionName: String
    let releaseDate: String
    let collectionCensoredName: String
    let trackName: String
    let trackPrice: Double
    let primaryGenreName: String
}

class CustomTableViewCell: UITableViewCell {
    @IBOutlet weak var artworkImageView: UIImageView!
    @IBOutlet weak var collectionPriceLabel: UILabel!
    @IBOutlet weak var collectionNameLabel: UILabel!
    @IBOutlet weak var releaseDateLabel: UILabel!
    
    func setImageFromURL(_ urlString: String) {
        guard let url = URL(string: urlString) else {
            return
        }
        
        DispatchQueue.global().async {
            if let data = try? Data(contentsOf: url) {
                DispatchQueue.main.async {
                    self.artworkImageView.image = UIImage(data: data)
                }
            }
        }
    }
}

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    var searchResults: [SearchResult] = []
    var searchText: String = ""
    var currentPage = 1
    var totalResults = 0
    let resultsPerPage = 20
    var previousOffset = 0
    var previousSearchResults: [SearchResult] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchBar.delegate = self
        
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.reloadData()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.count > 2 {
            self.searchText = searchText.replacingOccurrences(of: " ", with: "+")
            print(searchText)
            segmentedControlValueChanged(segmentedControl)
        }
        else{
            searchResults = []
            tableView.reloadData()
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        print("End searching --> Close Keyboard")
        self.searchBar.endEditing(true)
    }
    
    @IBAction func segmentedControlValueChanged(_ sender: UISegmentedControl) {
        currentPage = 1
        previousOffset = 0
        previousSearchResults = []
        searchiTunesAPI(searchText: searchText, media: getSelectedEntityType(), page: currentPage) { searchResults in
            self.searchResults = searchResults
            self.tableView.reloadData()
        }
    }
    
    func searchiTunesAPI(searchText: String, media: String, page: Int, completion: @escaping ([SearchResult]) -> Void) {
        let offset = (page - 1) * resultsPerPage
        let urlString = "https://itunes.apple.com/search?term=\(searchText)&entity=\(media)&offset=\(offset)&country=TR&sort=popularity"
        print(urlString)
        
        guard let url = URL(string: urlString) else {
            print("Invalid URL: \(urlString)")
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            if let error = error {
                print("Error occurred: \(error.localizedDescription)")
                return
            }
            
            if let data = data {
                do {
                    let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                    if let results = json?["results"] as? [[String: Any]],
                       let total = json?["resultCount"] as? Int {
                        
                        self.totalResults = total
                        
                        var searchResults: [SearchResult] = []
                        for result in results {
                            if let artworkUrl100 = result["artworkUrl100"] as? String,
                               let collectionPrice = result["collectionPrice"] as? Double,
                               let collectionName = result["collectionName"] as? String,
                               let releaseDate = result["releaseDate"] as? String,
                               let collectionCensoredName = result["collectionCensoredName"] as? String,
                               let trackName = result["trackName"] as? String,
                               let trackPrice = result["trackPrice"] as? Double,
                               let primaryGenreName = result["primaryGenreName"] as? String {
                                
                                let searchResult = SearchResult(artworkUrl100: artworkUrl100, collectionPrice: collectionPrice, collectionName: collectionName, releaseDate: releaseDate, collectionCensoredName: collectionCensoredName, trackName: trackName, trackPrice: trackPrice, primaryGenreName: primaryGenreName)
                                
                                searchResults.append(searchResult)
                            }
                        }
                        
                        DispatchQueue.main.async {
                            completion(searchResults)
                        }
                    }
                } catch {
                    print("JSON conversion error: \(error.localizedDescription)")
                }
            }
        }
        
        task.resume()
    }
    
    func getSelectedEntityType() -> String {
        switch segmentedControl.selectedSegmentIndex {
        case 0:
            return "movie"
        case 1:
            return "music"
        case 2:
            return "ebook"
        case 3:
            return "podcast"
        case 4:
            return ""
        default:
            return ""
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CustomCell", for: indexPath) as! CustomTableViewCell
        
        if indexPath.row < searchResults.count {
            let searchResult = searchResults[indexPath.row]
            cell.collectionNameLabel.text = searchResult.trackName
            cell.collectionPriceLabel.text = "\(searchResult.trackPrice)₺"
            
            if let date = convertToDate(from: searchResult.releaseDate) {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "dd.MM.yyyy"
                
                cell.releaseDateLabel.text = dateFormatter.string(from: date)
            }
            
            cell.setImageFromURL(searchResult.artworkUrl100)
        }
        
        return cell
    }
    
    func convertToDate(from dateString: String) -> Date? {
        let dateFormatter = ISO8601DateFormatter()
        return dateFormatter.date(from: dateString)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "DetailSegue", let detailVC = segue.destination as? DetailViewController {
            if let searchResult = sender as? SearchResult {
                detailVC.searchResult = searchResult
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let searchResult = searchResults[indexPath.row]
        performSegue(withIdentifier: "DetailSegue", sender: searchResult)
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let lastRowIndex = tableView.numberOfRows(inSection: 0) - 1
        
        if indexPath.row == lastRowIndex {
            if searchResults.count < totalResults {
                currentPage += 1
                previousOffset += resultsPerPage
                previousSearchResults += searchResults
                
                searchiTunesAPI(searchText: searchText, media: getSelectedEntityType(), page: currentPage) { searchResults in
                    self.searchResults = self.previousSearchResults + searchResults
                    self.tableView.reloadData()
                }
            }
        }
    }
}
