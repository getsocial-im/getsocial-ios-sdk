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
