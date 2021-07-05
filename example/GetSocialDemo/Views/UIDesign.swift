enum UIDesign {
    enum Colors {
        // label color
        static let label: UIColor = {
            if #available(iOS 13.0, *) {
                return UIColor.label
            }
            return UIColor.black
        }()

        // label input
        static let inputText: UIColor = {
            if #available(iOS 13.0, *) {
                return UIColor.darkText
            }
            return UIColor.black
        }()

        // view background color
        static let viewBackground: UIColor = {
            if #available(iOS 13.0, *) {
                return UIColor.systemBackground
            }
            return UIColor.white
        }()
    }
}


extension UIStackView {
	func addFormRow(elements: [UIView]) {
		let row = UIStackView()
		row.axis = .horizontal
		row.alignment = .firstBaseline
		elements.forEach {
			row.addArrangedSubview($0)
		}
		NSLayoutConstraint.activate([
			elements.first!.widthAnchor.constraint(equalToConstant: 120)
		])
		self.addArrangedSubview(row)
	}
}

extension UIViewController {

	func install(_ child: UIViewController, inside: UIView? = nil) {
		addChild(child)
		child.view.translatesAutoresizingMaskIntoConstraints = false
		guard let viewEmbedInto = inside == nil ? self.view : inside else {
			return
		}
		viewEmbedInto.addSubview(child.view)
		NSLayoutConstraint.activate([
			child.view.leadingAnchor.constraint(equalTo: viewEmbedInto.leadingAnchor),
			child.view.trailingAnchor.constraint(equalTo: viewEmbedInto.trailingAnchor),
			child.view.topAnchor.constraint(equalTo: viewEmbedInto.topAnchor),
			child.view.bottomAnchor.constraint(equalTo: viewEmbedInto.bottomAnchor)
		])
		child.didMove(toParent: self)
	}

}
