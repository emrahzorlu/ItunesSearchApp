import UIKit


    class DetailViewController: UIViewController {
    
    @IBOutlet weak var artworkImageView: UIImageView!
    @IBOutlet weak var collectionPriceLabel: UILabel!
    @IBOutlet weak var collectionNameLabel: UILabel!
    @IBOutlet weak var releaseDateLabel: UILabel!
    @IBOutlet var primaryGenreNameLabel: UILabel!
    @IBOutlet var trackNameLabel: UILabel!
    @IBOutlet var trackPriceLabel: UILabel!
        
        
        
        var searchResult: SearchResult?
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let result = searchResult {
            collectionPriceLabel.text = "\(result.collectionPrice)₺"
            collectionNameLabel.text = result.collectionName
            trackPriceLabel.text = "\(result.trackPrice)₺"
            trackNameLabel.text = result.trackName
            primaryGenreNameLabel.text = "Type : \(result.primaryGenreName)"
            
            if let date = convertToDate(from: result.releaseDate) {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "dd.MM.yyyy"
                releaseDateLabel.text = dateFormatter.string(from: date)
            }
            
            loadImage(from: result.artworkUrl100)
        }
    }
    
    func convertToDate(from dateString: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        return dateFormatter.date(from: dateString)
    }
    
    func loadImage(from urlString: String) {
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
