import UIKit

class BeautifulView: UIView {
    static let application = UIApplication.shared

	var spinningView: SpinningView?
    @IBOutlet weak public var textField: UITextField!

	func setupView() {
        /* loading view and applying constraints */
        guard let view = loadViewFromNib() else { return }
        addSubview(view)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.topAnchor.constraint(equalTo: topAnchor).isActive = true
        view.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
    
        let vHeightAnchor = view.heightAnchor.constraint(equalToConstant: 70)
        vHeightAnchor.priority = .defaultLow
        vHeightAnchor.isActive = true
    
        view.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        view.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
    
        
        textField.delegate = self
    }
	
	func loadViewFromNib() -> UIView? {
        let bundle = Bundle(for: BeautifulView.self)
		let nib = UINib(nibName: "BeautifulView", bundle: bundle)
        return nib.instantiate(withOwner: self, options: nil).first as? UIView
	}

	private func returnRandomString() -> String {
		let anotherView = spinningView
		textField.delegate = nil
		anotherView?.startSpinning()
		return "random"
	}

	private func returnRandomInt() -> Int {
		return 10
	}
}

/*
 * Uh-oh, don't do this!
 */
extension BeautifulView: UITextFieldDelegate {}
