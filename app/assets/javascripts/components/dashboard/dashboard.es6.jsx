import ImageItem from './image_item.es6.jsx';
import NM from '../../api/global.es6';

const FollowStuffMessage = () => (
  <div id="follow-stuff-message">
    <span>There isn't anything here. </span>
    <span>Follow some <a href="/users">artists</a> </span>
    <span>or <a href="/collections">collections</a> to fix that.</span>
  </div>
);

class Dashboard extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      hasMoreImages: true,
      hasFetched: false,
      fetching: false,
      images: props.images
    }
  }

  render() {
    if(this.state.images.length === 0 && 
       (this.state.hasFetched || this.props.images.length == 0)) {
      return <FollowStuffMessage />;
    }
    var imgs = this.state.images.map((img, index) => {
      return <ImageItem {...img} 
          key={index} />;
    });
    var fetchBar = <div></div>;
    if(this.state.fetching) {
      fetchBar = <progress></progress>;
    }
    else if(! this.state.hasMoreImages) {
      fetchBar = <div>
        No more images
      </div>;
    }
    return <div>
      <ul className="frontpage-subscription-container"
        ref={(r) => this.listContainer = r}>
        {imgs}
      </ul>
      {fetchBar}
    </div>;
  }

  componentDidMount() {
    if(this.props.images.length !== 0) {
      $("body").on("scroll.dashboard touchmove.dashboard", 
      this.scrollWindow.bind(this));
    }

  }

  scrollWindow(event) {
    let r = this.listContainer.getBoundingClientRect();
    if(r.bottom - 100 <= window.innerHeight && ! this.state.fetching) {
      this.fetchFurther();
    }
  }

  async fetchFurther() {
    if(this.state.fetching || ! this.state.hasMoreImages) {
      return;
    }
    this.setState({
      fetching: true
    });
    let url = "/";
    if(this.state.images.length > 0) {
      let last = this.state.images[this.state.images.length - 1];
      let date = new Date(last.sort_created_at).getTime() / 1000;
      url = `/?fetch_after=${date}`;
    }
    let resp = await NM.getJSON(url);
    let images = resp.images;
    if(images.length > 0) {
      this.setState({
        fetching: false,
        hasFetched: true,
        images: [...this.state.images, ...images]
      });
    }
    else {
      $("body").off("scroll.dashboard touchmove.dashboard");
      this.setState({
        hasMoreImages: false,
        hasFetched: true,
        fetching: false
      });
    }
  }
}



window.Dashboard = Dashboard;
export default Dashboard;
