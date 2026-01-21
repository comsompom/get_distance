import UIKit

class TutorialViewController: UIViewController {

    private let textView = UITextView()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Tutorial"
        view.backgroundColor = .systemBackground
        setupUI()
    }

    private func setupUI() {
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.isEditable = false
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.text = """
        Quick Tutorial

        1) Point the camera at the person/animal.
        2) Tap the top of the object.
        3) Tap the bottom of the object.
        4) Choose a height preset or enter a custom height.
        5) Read the distance and confidence.

        Tips:
        - Hold the phone steady.
        - Make sure lighting is good.
        - Tap precisely on top and bottom.
        """

        view.addSubview(textView)
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            textView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])
    }
}
