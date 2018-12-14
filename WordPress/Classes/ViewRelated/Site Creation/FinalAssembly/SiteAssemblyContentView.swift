
import UIKit

// MARK: SiteAssemblyContentView

/// This view is intended for use as the root view of `SiteAssemblyWizardContent`.
/// It manages the state transitions that occur as a site is assembled via remote service dialogue.
///
final class SiteAssemblyContentView: UIView {

    // MARK: Properties

    private struct Parameters {
        static let animationDuration                        = TimeInterval(0.5)
        static let buttonContainerScaleFactor               = CGFloat(2)
        static let horizontalMargin                         = CGFloat(30)
        static let verticalSpacing                          = CGFloat(30)
        static let statusStackViewSpacing                   = CGFloat(16)
    }

    private var completionLabelTopConstraint: NSLayoutConstraint?

    private(set) var completionLabel: UILabel

    private let statusLabel: UILabel

    private let activityIndicator: UIActivityIndicatorView

    private(set) var statusStackView: UIStackView

    private var assembledSiteTopConstraint: NSLayoutConstraint?

    private var assembledSiteHeightConstraint: NSLayoutConstraint?

    private var assembledSiteWidthConstraint: NSLayoutConstraint?

    private(set) var assembledSiteView: AssembledSiteView?

    private var buttonContainerBottomConstraint: NSLayoutConstraint?

    private var buttonContainerContainer: UIView?

    var buttonContainerView: UIView? {
        didSet {
            installButtonContainerView()
        }
    }

    var domainName: String? {
        didSet {
            installAssembledSiteView()
        }
    }

    var status: SiteAssemblyStatus = .idle {
        didSet {
            setNeedsLayout()
        }
    }

    // MARK: SiteAssemblyContentView

    init() {
        self.completionLabel = {
            let label = UILabel()

            label.translatesAutoresizingMaskIntoConstraints = false
            label.numberOfLines = 0

            label.font = WPStyleGuide.fontForTextStyle(.title1, fontWeight: .bold)
            label.textColor = WPStyleGuide.darkGrey()
            label.textAlignment = .center

            let createdText = NSLocalizedString("Your site has been created!",
                                              comment: "User-facing string, presented to reflect that site assembly completed successfully.")
            label.text = createdText
            label.accessibilityLabel = createdText

            return label
        }()

        self.statusLabel = {
            let label = UILabel()

            label.translatesAutoresizingMaskIntoConstraints = false
            label.numberOfLines = 0

            label.font = WPStyleGuide.fontForTextStyle(.title2)
            label.textColor = WPStyleGuide.greyDarken10()
            label.textAlignment = .center

            let statusText = NSLocalizedString("We’re creating your new site.",
                                               comment: "User-facing string, presented to reflect that site assembly is underway.")
            label.text = statusText
            label.accessibilityLabel = statusText

            return label
        }()

        self.activityIndicator = {
            let activityIndicator = UIActivityIndicatorView(style: .whiteLarge)

            activityIndicator.translatesAutoresizingMaskIntoConstraints = false
            activityIndicator.hidesWhenStopped = true
            activityIndicator.color = WPStyleGuide.greyDarken10()
            activityIndicator.startAnimating()

            return activityIndicator
        }()

        self.statusStackView = {
            let stackView = UIStackView()

            stackView.translatesAutoresizingMaskIntoConstraints = false
            stackView.alignment = .center
            stackView.axis = .vertical
            stackView.spacing = Parameters.statusStackViewSpacing

            return stackView
        }()

        super.init(frame: .zero)

        configure()
    }

    func adjustConstraints() {
        guard let assembledSitePreferredSize = assembledSiteView?.preferredSize,
            let widthConstraint = assembledSiteWidthConstraint else {

            return
        }

        widthConstraint.constant = assembledSitePreferredSize.width
        layoutIfNeeded()
    }

    // MARK: UIView

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        switch status {
        case .idle:
            layoutIdle()
        case .inProgress:
            layoutInProgress()
        case .failed:
            layoutFailed()
        case .succeeded:
            assembledSiteView?.urlString = "https://longreads.com"
            layoutSucceeded()
        }
    }

    // MARK: Private behavior

    private func configure() {
        translatesAutoresizingMaskIntoConstraints = true
        autoresizingMask = [ .flexibleWidth, .flexibleHeight ]

        backgroundColor = WPStyleGuide.greyLighten30()

        statusStackView.addArrangedSubviews([ statusLabel, activityIndicator ])
        addSubviews([ completionLabel, statusStackView ])

        let completionLabelTopInsetInitial = Parameters.verticalSpacing * 2
        let completionLabelInitialTopConstraint = completionLabel.topAnchor.constraint(equalTo: prevailingLayoutGuide.topAnchor, constant: completionLabelTopInsetInitial)
        self.completionLabelTopConstraint = completionLabelInitialTopConstraint

        NSLayoutConstraint.activate([
            completionLabelInitialTopConstraint,
            completionLabel.leadingAnchor.constraint(equalTo: prevailingLayoutGuide.leadingAnchor, constant: Parameters.horizontalMargin),
            completionLabel.trailingAnchor.constraint(equalTo: prevailingLayoutGuide.trailingAnchor, constant: -Parameters.horizontalMargin),
            completionLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            statusStackView.leadingAnchor.constraint(equalTo: prevailingLayoutGuide.leadingAnchor, constant: Parameters.horizontalMargin),
            statusStackView.trailingAnchor.constraint(equalTo: prevailingLayoutGuide.trailingAnchor, constant: -Parameters.horizontalMargin),
            statusStackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            statusStackView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    private func installAssembledSiteView() {
        guard let domainName = domainName else {
            return
        }

        let assembledSiteView = AssembledSiteView(domainName: domainName)
        addSubview(assembledSiteView)

        if let buttonContainer = buttonContainerContainer {
            bringSubviewToFront(buttonContainer)
        }

        let initialSiteTopConstraint = assembledSiteView.topAnchor.constraint(equalTo: bottomAnchor)
        self.assembledSiteTopConstraint = initialSiteTopConstraint

        let assembledSiteTopInset = Parameters.verticalSpacing

        let preferredAssembledSiteSize = assembledSiteView.preferredSize
        let assembledSiteHeightConstraint = assembledSiteView.heightAnchor.constraint(greaterThanOrEqualToConstant: preferredAssembledSiteSize.height)
        self.assembledSiteHeightConstraint = assembledSiteHeightConstraint

        let assembledSiteWidthConstraint = assembledSiteView.widthAnchor.constraint(equalToConstant: preferredAssembledSiteSize.width)
        self.assembledSiteWidthConstraint = assembledSiteWidthConstraint

        NSLayoutConstraint.activate([
            initialSiteTopConstraint,
            assembledSiteView.topAnchor.constraint(greaterThanOrEqualTo: completionLabel.bottomAnchor, constant: assembledSiteTopInset),
            assembledSiteView.bottomAnchor.constraint(greaterThanOrEqualTo: bottomAnchor),
            assembledSiteView.centerXAnchor.constraint(equalTo: centerXAnchor),
            assembledSiteWidthConstraint,
            assembledSiteHeightConstraint
        ])

        self.assembledSiteView = assembledSiteView
    }

    private func installButtonContainerView() {
        guard let buttonContainerView = buttonContainerView else {
            return
        }

        // This wrapper view provides underlap for Home indicator
        let buttonContainerContainer = UIView(frame: .zero)
        buttonContainerContainer.translatesAutoresizingMaskIntoConstraints = false
        buttonContainerContainer.backgroundColor = .white
        buttonContainerContainer.addSubview(buttonContainerView)
        addSubview(buttonContainerContainer)
        self.buttonContainerContainer = buttonContainerContainer

        let buttonContainerHeight = buttonContainerView.bounds.height
        let safelyOffscreen = Parameters.buttonContainerScaleFactor * buttonContainerHeight
        let bottomConstraint = buttonContainerView.bottomAnchor.constraint(equalTo: prevailingLayoutGuide.bottomAnchor, constant: safelyOffscreen)
        self.buttonContainerBottomConstraint = bottomConstraint

        NSLayoutConstraint.activate([
            buttonContainerView.topAnchor.constraint(equalTo: buttonContainerContainer.topAnchor),
            buttonContainerView.leadingAnchor.constraint(equalTo: buttonContainerContainer.leadingAnchor),
            buttonContainerView.trailingAnchor.constraint(equalTo: buttonContainerContainer.trailingAnchor),
            buttonContainerContainer.heightAnchor.constraint(equalTo: buttonContainerView.heightAnchor, multiplier: Parameters.buttonContainerScaleFactor),
            buttonContainerContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            buttonContainerContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            bottomConstraint,
        ])
    }

    private func layoutIdle() {
        completionLabel.alpha = 0
        statusStackView.alpha = 0
    }

    private func layoutInProgress() {
        UIView.animate(withDuration: Parameters.animationDuration, delay: 0, options: .curveEaseOut, animations: { [statusStackView] in
            statusStackView.alpha = 1
        })
    }

    private func layoutFailed() {
        debugPrint(#function)
    }

    private func layoutSucceeded() {
        UIView.animate(withDuration: Parameters.animationDuration, delay: 0, options: .curveEaseOut, animations: { [statusStackView] in
            statusStackView.alpha = 0
            }, completion: { [weak self] completed in
                guard completed, let strongSelf = self else {
                    return
                }

                let completionLabelTopInsetFinal = Parameters.verticalSpacing
                strongSelf.completionLabelTopConstraint?.constant = completionLabelTopInsetFinal

                strongSelf.assembledSiteTopConstraint?.isActive = false
                let transitionConstraint = strongSelf.assembledSiteView?.topAnchor.constraint(equalTo: strongSelf.completionLabel.bottomAnchor, constant: Parameters.verticalSpacing)
                transitionConstraint?.isActive = true
                strongSelf.assembledSiteTopConstraint = transitionConstraint

                strongSelf.buttonContainerBottomConstraint?.constant = 0

                UIView.animate(withDuration: Parameters.animationDuration,
                               delay: 0,
                               options: .curveEaseOut,
                               animations: { [weak self] in
                                guard let strongSelf = self else {
                                    return
                                }

                                strongSelf.completionLabel.alpha = 1
                                strongSelf.layoutIfNeeded()
                })
        })
    }
}