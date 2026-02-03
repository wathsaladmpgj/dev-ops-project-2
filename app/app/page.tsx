export default function Home() {
  return (
    <div className="min-h-screen">
      {/* Hero Section */}
      <section className="relative h-screen flex items-center justify-center bg-gradient-to-br from-blue-500 via-purple-500 to-pink-500">
        <div className="absolute inset-0 bg-black opacity-20"></div>
        <div className="relative z-10 text-center text-white px-4">
          <h1 className="text-5xl md:text-7xl font-bold mb-6">
            Explore the World
          </h1>
          <p className="text-xl md:text-2xl mb-8 max-w-2xl mx-auto">
            Discover amazing destinations and create unforgettable memories
          </p>
          <button className="bg-white text-purple-600 px-8 py-4 rounded-full font-semibold text-lg hover:bg-opacity-90 transition-all transform hover:scale-105">
            Start Your Journey
          </button>
        </div>
      </section>

      {/* Popular Destinations */}
      <section className="py-20 px-4 bg-gray-50">
        <div className="max-w-7xl mx-auto">
          <h2 className="text-4xl font-bold text-center mb-12 text-gray-800">
            Popular Destinations
          </h2>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
            {/* Destination 1 */}
            <div className="bg-white rounded-lg shadow-lg overflow-hidden transform hover:scale-105 transition-transform">
              <div className="h-64 bg-gradient-to-br from-blue-400 to-blue-600 flex items-center justify-center">
                <span className="text-6xl">🏖️</span>
              </div>
              <div className="p-6">
                <h3 className="text-2xl font-bold mb-2 text-gray-800">Tropical Paradise</h3>
                <p className="text-gray-600 mb-4">
                  Relax on pristine beaches with crystal clear waters
                </p>
                <button className="text-purple-600 font-semibold hover:underline">
                  Learn More →
                </button>
              </div>
            </div>

            {/* Destination 2 */}
            <div className="bg-white rounded-lg shadow-lg overflow-hidden transform hover:scale-105 transition-transform">
              <div className="h-64 bg-gradient-to-br from-green-400 to-green-600 flex items-center justify-center">
                <span className="text-6xl">🏔️</span>
              </div>
              <div className="p-6">
                <h3 className="text-2xl font-bold mb-2 text-gray-800">Mountain Adventures</h3>
                <p className="text-gray-600 mb-4">
                  Experience breathtaking views and thrilling activities
                </p>
                <button className="text-purple-600 font-semibold hover:underline">
                  Learn More →
                </button>
              </div>
            </div>

            {/* Destination 3 */}
            <div className="bg-white rounded-lg shadow-lg overflow-hidden transform hover:scale-105 transition-transform">
              <div className="h-64 bg-gradient-to-br from-orange-400 to-red-600 flex items-center justify-center">
                <span className="text-6xl">🏛️</span>
              </div>
              <div className="p-6">
                <h3 className="text-2xl font-bold mb-2 text-gray-800">Historic Cities</h3>
                <p className="text-gray-600 mb-4">
                  Explore rich culture and ancient architecture
                </p>
                <button className="text-purple-600 font-semibold hover:underline">
                  Learn More →
                </button>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Features Section */}
      <section className="py-20 px-4">
        <div className="max-w-7xl mx-auto">
          <h2 className="text-4xl font-bold text-center mb-12 text-gray-800">
            Why Choose Us
          </h2>
          <div className="grid grid-cols-1 md:grid-cols-4 gap-8">
            <div className="text-center">
              <div className="text-5xl mb-4">✈️</div>
              <h3 className="text-xl font-bold mb-2 text-gray-800">Best Prices</h3>
              <p className="text-gray-600">Competitive rates for all destinations</p>
            </div>
            <div className="text-center">
              <div className="text-5xl mb-4">🌟</div>
              <h3 className="text-xl font-bold mb-2 text-gray-800">Expert Guides</h3>
              <p className="text-gray-600">Professional and knowledgeable staff</p>
            </div>
            <div className="text-center">
              <div className="text-5xl mb-4">🛡️</div>
              <h3 className="text-xl font-bold mb-2 text-gray-800">Safe Travel</h3>
              <p className="text-gray-600">Your safety is our priority</p>
            </div>
            <div className="text-center">
              <div className="text-5xl mb-4">💼</div>
              <h3 className="text-xl font-bold mb-2 text-gray-800">24/7 Support</h3>
              <p className="text-gray-600">We're here whenever you need us</p>
            </div>
          </div>
        </div>
      </section>

      {/* Footer */}
      <footer className="bg-gray-800 text-white py-12 px-4">
        <div className="max-w-7xl mx-auto text-center">
          <p className="text-lg mb-2">Ready to start your adventure?</p>
          <p className="text-gray-400">© 2026 Travel World. All rights reserved.</p>
        </div>
      </footer>
    </div>
  );
}
