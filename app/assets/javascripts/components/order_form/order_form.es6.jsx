import OptionForm from './option_form.es6.jsx';

function aspectSort(a, b) {
  var o = a.option_id - b.option_id;
  return o ? o : a.id - b.id;
}

class OrderForm extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      aspects: (props.aspects || [])
    };
  }

  render() {
    var aspects = this.state.aspects
      .sort(aspectSort);
    var options = this.props.listing.options
      .sort((a, b) => a.id - b.id)
      .map((o) => {
        var underAspects = aspects.filter((a) => a.option_id === o.id);
        return <OptionForm
          key={o.id}
          {...o}
          aspects={underAspects}
          addAspect={this.addAspect.bind(this, o)} />
      });
    console.log(options);
    return <div>
      <div className="options-container">
        {options}
      </div>
    </div>;
  }

  addAspect(option) {
    this.setState({
      aspects: [...this.state.aspects, {option_id: option.id}]
    });
  }
}

window.OrderForm = OrderForm;
export default OrderForm;
